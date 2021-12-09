# The following test cases and comments are adapted from http://brainfuck.org/tests.b

using Test
if !@isdefined(BrainFuck)
    include(joinpath(@__DIR__, "..", "src", "BrainFuck.jl"))
end
output = IOBuffer()

# Here are some little programs for testing brainfuck implementations.

@testset "IO test" begin
    # This is for testing i/o; give it a return followed by an EOF. (Try it both
    # with file input — a file consisting only of one blank line — and with
    # keyboard input, i.e. hit return and then ctrl-d (Unix) or ctrl-z (Windows).)
    # It should give two lines of output; the two lines should be identical, and
    # should be lined up one over the other. If that doesn't happen, ten is not
    # coming through as newline on output.
    # The content of the lines tells how input is being processed; each line
    # should be two uppercase letters.
    # Anything with O in it means newline is not coming through as ten on input.
    # LK means newline input is working fine, and EOF leaves the cell unchanged
    # (which I recommend).
    # LB means newline input is working fine, and EOF translates as 0.
    # LA means newline input is working fine, and EOF translates as -1.
    # Anything else is fairly unexpected.
    iotest = ">,>+++++++++,>+++++++++++[<++++++<++++++<+>>>-]<<.>.<<-.>.>.<<."

    BrainFuck.interpret(iotest, input = "\n", output = output)
    @test String(take!(output)) == "LK\nLK\n"

    BrainFuck.interpret(iotest, input = open(joinpath(@__DIR__, "empty.txt")), output = output)
    @test String(take!(output)) == "LK\nLK\n"
end

@testset "Memory size" begin
    memorysizetest = "++++[>++++++<-]>[>+++++>+++++++<<-]>>++++<[[>[[>>+<<-]<]>>>-]>-[>+>+<<-]>]+++++[>+++++++<<++>-]>.<<."
    # Goes to cell 30000 and reports from there with a #. (Verifies that the
    # array is big enough.)
    BrainFuck.interpret(memorysizetest, output = output)
    @test String(take!(output)) == "#\n"

    BrainFuck.compile(memorysizetest)(output = output)
    @test String(take!(output)) == "#\n"
end

@testset "Several obscure tests" begin
    # Tests for several obscure problems. Should output an H.
    obscuretest = """[]++++++++++[>>+>+>++++++[<<+<+++>>>-]<<<<-]
    "A*\$";?@![#>>+<<]>[>>]<<<<[>++<[-]]>.>."""
    @test BrainFuck.interpret(obscuretest, output = String) == "H\n"
    @test BrainFuck.compile(obscuretest)(output = String) == "H\n"
end

@testset "Unmatched brackets" begin
    # Should ideally give error message "unmatched [" or the like, and not give
    # any output. Not essential.
    unmatchedleft = "+++++[>+++++++>++<<-]>.>.["
    @test_throws ArgumentError BrainFuck.interpret(unmatchedleft)
    @test_throws ArgumentError BrainFuck.compile(unmatchedleft)

    # Should ideally give error message "unmatched ]" or the like, and not give
    # any output. Not essential.
    unmatchedright = "+++++[>+++++++>++<<-]>.>.]["
    @test_throws ArgumentError BrainFuck.interpret(unmatchedright)
    @test_throws ArgumentError BrainFuck.compile(unmatchedright)
end

@testset "Deep brackets" begin
    # [Daniel Cristofani's] pathological program rot13.b is good for testing the
    # response to deep brackets; the input "~mlk zyx" should produce the output "~zyx mlk".
    rot13 = """
        ,
        [>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-
        [>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-
        [>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-
        [>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-
        [>++++++++++++++<-
        [>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-
        [>>+++++[<----->-]<<-
        [>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-
        [>++++++++++++++<-
        [>+<-[>+<-[>+<-[>+<-[>+<-
        [>++++++++++++++<-
        [>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-
        [>>+++++[<----->-]<<-
        [>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-[>+<-
        [>++++++++++++++<-
        [>+<-]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]
        ]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]>.[-]<,]
        """

    @test BrainFuck.interpret(rot13, input = "~mlk zyx", output = String) == "~zyx mlk"
    @test BrainFuck.compile(rot13)(input = "~mlk zyx", output = String) == "~zyx mlk"
end
