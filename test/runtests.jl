using PackedASCIITypes
using Test

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

@test "small tests" begin
    for (T, l) in [(PackedASCII1, 1),
                   (PackedASCII2, 2),
                   (PackedASCII4, 4)]
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
