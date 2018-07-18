__precompile__()
module PackedASCIITypes

export PackedASCII, @pasc_str

using Base: StringVector
import Base: length, ==, hash, <, typemin, show, String, convert, promote_rule

abstract type PackedASCII end

primitive type PackedASCII1 <: PackedASCII 8 end
primitive type PackedASCII2 <: PackedASCII 16 end
primitive type PackedASCII4 <: PackedASCII 32 end
primitive type PackedASCII8 <: PackedASCII 64 end
primitive type PackedASCII17 <: PackedASCII 128 end

"""
    maxlength(::Type{<:PackedASCIIString})

Maximum number of characters allowed by a type.
"""
function maxlength end

for (T, S, maxlen, lenbits) in [(PackedASCII1, UInt8, 1, 1),
                                (PackedASCII2, UInt16, 2, 2),
                                (PackedASCII4, UInt32, 4, 3),
                                (PackedASCII8, UInt64, 8, 4),
                                (PackedASCII17, UInt128, 17, 5)]
    # sanity checks and useful quantities
    @assert maxlen+1 ≤ 2^lenbits
    nbits = sizeof(S)*8
    @assert nbits ≥ maxlen*7 + lenbits
    firstoffset = lenbits + (maxlen - 1) * 7 # first char starts here
    lenmask = S(2^lenbits - 1)              # extract length bits

    @eval length(p::$T) = Int(reinterpret($S, p) & $lenmask)

    # reflection
    @eval maxlength(::Type{$T}) = $maxlen

    # compose and decompose
    @eval function _compose(::Type{$T}, s::$S, len::Integer)
        u = s << ($lenbits + 7 * ($maxlen - len))
        u |= $S(len)
        reinterpret($T, u)
    end
    @eval _compose(::Type{$T}, s, len) = _compose($T, convert($S, s), len)

    @eval function _decompose(p::$T)
        u = reinterpret($S, p)
        len = u & $lenmask
        s = u >> ($lenbits + 7*($maxlen - len))
        s, len
    end

    # conversion to and from String
    Tname = nameof(T)
    @eval export $(Tname)

    @eval function ($Tname)(str::AbstractString)
        len = length(str)
        (len ≤ $maxlen && isascii(str)) || throw(InexactError(Symbol($(Tname)), $(T), str))
        s = zero($S)
        for c in str
            s <<= 7
            s |= $S(c)
        end
        _compose($T, s, len)
    end
    @eval ($Tname)(p::$T) = p
    @eval ($Tname)(p::PackedASCII) = convert($T, p)
    @eval function String(p::$T)
        len = length(p)
        sv = StringVector(len)
        u = reinterpret($S, p)
        for i in 1:len
            sv[i] = UInt8((u >> $firstoffset) & 0x7f)
            u <<= 7
        end
        String(sv)
    end

    # read macro
    readT = Symbol("pasc$(maxlen)_str")
    readTmacro = Symbol("@" * string(readT))
    @eval export $(readTmacro)
    @eval macro ($readT)(str)
        $T(str)
    end

    # methods
    @eval (==)(p::$T, q::$T) = reinterpret($S, p) == reinterpret($S, q)
    @eval function hash(p::$T, h::UInt)
        s, len = _decompose(p)
        hash(s, hash(len, h))
    end
    @eval (<)(p::$T, q::$T) = reinterpret($S, p) < reinterpret($S, q)
    @eval typemin(::Type{$T}) = reinterpret($T, zero($S))
    @eval show(io::IO, p::$T) = print(io, "pasc$($(maxlen))\"", String(p), "\"")
end

function convert(::Type{T}, p::S) where {T <: PackedASCII, S <: PackedASCII}
    shiftedbits, len = _decompose(p)
    _compose(T, shiftedbits, len)
end

function (==)(p::PackedASCII, q::PackedASCII)
    sa, lena = _decompose(p)
    sb, lenb = _decompose(q)
    lena == lenb && sa == sb
end

function PackedASCII(s::String)
    len = length(s)
    if len ≤ 1              # FIXME ugly implementation, worth code generation?
        PackedASCII1(s)
    elseif len ≤ 2
        PackedASCII2(s)
    elseif len ≤ 4
        PackedASCII4(s)
    elseif len ≤ 8
        PackedASCII8(s)
    elseif len ≤ 17
        PackedASCII17(s)
    else
        throw(InexactError(PackedASCII, PackedASCIIString, s))
    end
end

macro pasc_str(str)
    PackedASCII(str)
end

promote_rule(::Type{T}, ::Type{S}) where {T <: PackedASCII, S <: PackedASCII} =
    maxlength(T) ≥ maxlength(S) ? T : S

(<)(a::PackedASCII, b::PackedASCII) = (<)(promote(a, b)...)

end # module
