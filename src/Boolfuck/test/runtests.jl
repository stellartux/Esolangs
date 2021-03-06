using Test
if !@isdefined(interpret)
    include("../src/boolfuck.jl")
end

# brainfucktoboolfuck = let commands = Dict((
#     '+' => ">[>]+<[+<]>>>>>>>>>[+]<<<<<<<<<",
#     '-' => ">>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+]<<<<<<<<<",
#     '<' => "<<<<<<<<<",
#     '>' => ">>>>>>>>>",
#     ',' => ">,>,>,>,>,>,>,>,<<<<<<<<",
#     '.' => ">;>;>;>;>;>;>;>;<<<<<<<<",
#     '[' => ">>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+<<<<<<<<[>]+<[+<]",
#     ']' => ">>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>]<[+<]"
# ))
# (brainfuck) -> join(get(commands, command, "") for command in brainfuck)
# end

@testset "Hello, world!" begin
    helloworld = """;;;+;+;;+;+;
        +;+;+;+;;+;;+;
        ;;+;;+;+;;+;
        ;;+;;+;+;;+;
        +;;;;+;+;;+;
        ;;+;;+;+;+;;
        ;;;;;+;+;;
        +;;;+;+;;;+;
        +;;;;+;+;;+;
        ;+;+;;+;;;+;
        ;;+;;+;+;;+;
        ;;+;+;;+;;+;
        +;+;;;;+;+;;
        ;+;+;+;"""

    @test interpret(helloworld) == "Hello, world!\n"
    @test compile(helloworld)() == "Hello, world!\n"
end

@testset "Multiply" begin
    multiply = ">,>,>,>,>,>,>,>,>>,>,>,>,>,>,>,>,<<<<<<<<+<<<<<<<<+[>+]<[<]>>>>>>>>>[+<<<<<<<<[>]+<[+<]>>>>>>>>>>>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+<<<<<<<<[>]+<[+<]>>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+]>[>]+<[+<]>>>>>>>>>[+]>[>]+<[+<]>>>>>>>>>[+]<<<<<<<<<<<<<<<<<<+<<<<<<<<+[>+]<[<]>>>>>>>>>]<[+<]>>>>>>>>>>>>>>>>>>>>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+<<<<<<<<[>]+<[+<]>>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+]<<<<<<<<<<<<<<<<<<<<<<<<<<[>]+<[+<]>>>>>>>>>[+]>>>>>>>>>>>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>]<[+<]<<<<<<<<<<<<<<<<<<+<<<<<<<<+[>+]<[<]>>>>>>>>>[+]+<<<<<<<<+[>+]<[<]>>>>>>>>>]<[+<]>>>>>>>>>>>>>>>>>>>;>;>;>;>;>;>;>;<<<<<<<<"
    m = compile(multiply)
    @test m(join(Char[4, 5])) == join(Char[20])
end

@testset "Fibonacci Numbers" begin
    fibsbelow = let fibcache = [1, 1]
        function fib(n::Integer)
            while length(fibcache) < n
                push!(fibcache, fibcache[end-1] + fibcache[end])
            end
            view(fibcache, 1:n)
        end
    end
    julia_f(n) = join(fibsbelow(n), ", ")

    fibonacci = brainfucktoboolfuck(",>+>>>>++++++++++++++++++++++++++++++++++++++++++++>++++++++++++++++++++++++++++++++<<<<<<[>[>>>>>>+>+<<<<<<<-]>>>>>>>[<<<<<<<+>>>>>>>-]<[>++++++++++[-<-[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]>[<<[>>>+<<<-]>>[-]]<<]>>>[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]>[<<+>>[-]]<<<<<<<]>>>>>[++++++++++++++++++++++++++++++++++++++++++++++++.[-]]++++++++++<[->-<]>++++++++++++++++++++++++++++++++++++++++++++++++.[-]<<<<<<<<<<<<[>>>+>+<<<<-]>>>>[<<<<+>>>>-]<-[>>.>.<<<[-]]<<[>>+>+<<<-]>>>[<<<+>>>-]<<[<+>-]>[<+>-]<<<-]")
    f = compile(fibonacci)

    for n in rand(1:9, 3)
        @test julia_f(n) == f(String(Char[n]))
    end
end
