using PackedASCIITypes
using Test

const TYPEINFO = [(PackedASCII1, 1),
                  (PackedASCII2, 2),
                  (PackedASCII4, 4),
                  (PackedASCII8, 8),
                  (PackedASCII17, 17)]

@testset "non-standard literals and creation" begin
    @test pasc1"a"::PackedASCII1 ≡ pasc"a"::PackedASCII1 ≡ PackedASCII1("a") ≡
        PackedASCII("a")
    @test pasc2"ab"::PackedASCII2 ≡ pasc"ab"::PackedASCII2 ≡
        PackedASCII2("ab") ≡ PackedASCII("ab")
    @test pasc4"abcd"::PackedASCII4 ≡ pasc"abcd"::PackedASCII4 ≡
        PackedASCII4("abcd") ≡ PackedASCII("abcd")
    @test pasc8"abcdefgh"::PackedASCII8 ≡ pasc"abcdefgh"::PackedASCII8 ≡
        PackedASCII8("abcdefgh") ≡ PackedASCII("abcdefgh")
    @test pasc17"fourtytwo"::PackedASCII17 ≡ pasc"fourtytwo"::PackedASCII17 ≡
        PackedASCII17("fourtytwo") ≡ PackedASCII("fourtytwo")
end

@testset "small tests" begin
    for (T, l) in TYPEINFO
        @test PackedASCIITypes.maxlength(T) == l
        str = reduce(*, rand('a':'z', l))
        p = T(str)
        @test p isa T
        @test String(p) == str
        @test_throws InexactError T(str * 'x')
        a = T("a")
        b = T("b")
        @test a ≡ a
        @test a == a
        @test b ≠ a
        if l ≥ 2
            aa = T("aa")
            @test a < aa < b
        else
            @test a < b
        end
        @test String(typemin(T)) == ""
        @test repr(a) == "pasc$(l)\"a\""
    end
end

@testset "mixing types, equality, hashing" begin
    a = pasc2"a"
    aa = pasc8"aa"
    b = pasc4"b"
    @test aa == pasc4"aa"
    @test a < b
    @test a < aa
    for T in first.(TYPEINFO)
        a2 = T(a)
        @test a == a2
        @test a2 < aa < T(b)
        @test hash(a) == hash(a2)
        h = rand(UInt)
        @test hash(a, h) == hash(a2, h)
    end
end

@testset "constructors" begin
    @test_throws InexactError PackedASCII("1"^18)
    @test_throws InexactError PackedASCII("pillangó")
end

@testset "I/O" begin
    io = IOBuffer()
    a = pasc1"a"
    for T in first.(TYPEINFO)
        write(io, T(a))
    end
    b = take!(io)
    @test length(b) == 2^5-1
    i = 0
    for T in first.(TYPEINFO)
        j = sizeof(T)
        a2 = reinterpret(T, b[i.+(1:j)])[1]
        @test T(a) ≡ a2::T
        i += j
    end
end
