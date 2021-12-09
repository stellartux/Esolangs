if !@isdefined(interpret)
    include("boolfuck.jl")
end

bffibo = brainfucktoboolfuck(",>+>>>>++++++++++++++++++++++++++++++++++++++++++++>++++++++++++++++++++++++++++++++<<<<<<[>[>>>>>>+>+<<<<<<<-]>>>>>>>[<<<<<<<+>>>>>>>-]<[>++++++++++[-<-[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]>[<<[>>>+<<<-]>>[-]]<<]>>>[>>+>+<<<-]>>>[<<<+>>>-]+<[>[-]<[-]]>[<<+>>[-]]<<<<<<<]>>>>>[++++++++++++++++++++++++++++++++++++++++++++++++.[-]]++++++++++<[->-<]>++++++++++++++++++++++++++++++++++++++++++++++++.[-]<<<<<<<<<<<<[>>>+>+<<<<-]>>>>[<<<<+>>>>-]<-[>>.>.<<<[-]]<<[>>+>+<<<-]>>>[<<<+>>>-]<<[<+>-]>[<+>-]<<<-]");
input = join(Char[10])

@time interpret(bffibo, input)
@time f = compile(bffibo)
@time f(input)

# Baseline - equivalent function in Julia
# 0.018314 seconds (53.82 k allocations: 3.214 MiB, 99.81% compilation time)
# 0.000014 seconds (31 allocations: 1.453 KiB)

# Time taken for fibonacci(10) in Boolfuck

# First interpreter
# 17.954638 seconds (6.12 M allocations: 200.450 MiB, 0.24% gc time, 4.89% compilation time)
# 16.866883 seconds (3.55 M allocations: 54.287 MiB, 0.05% gc time)

# Second interpreter avoiding excess memory use
# 15.507475 seconds (861.41 k allocations: 47.568 MiB, 0.06% gc time, 2.14% compilation time)
# 15.666484 seconds (90 allocations: 168.312 KiB)

# Third interpreter parser groups multiple +s and <>s
# 5.436422 seconds (147.41 k allocations: 8.672 MiB, 0.16% gc time, 1.89% compilation time)
# 5.266540 seconds (87 allocations: 168.172 KiB)

# First compiler - compile boolfuck to Julia
# Oneshot - 14.027388 seconds (3.92 M allocations: 183.405 MiB, 0.51% gc time, 97.50% compilation time)
# Compile only - 0.522731 seconds (509.95 k allocations: 30.057 MiB, 22.37% compilation time)
# Cold start - 13.808873 seconds (3.75 M allocations: 173.838 MiB, 1.44% gc time, 99.96% compilation time)
# Warm start - 0.004169 seconds (66 allocations: 7.188 KiB)

# Second compiler - change from gotos to while loops in compiled code


using Plots
function plotgraph()
    plot(
        [@elapsed f(String(Char[i])) for i = 1:50],
        label = "Compiled",
        xaxis = "n",
        yaxis = ("Time to calculate fib(n) in seconds, log10 scale", :log10)
    )
    plot!(
        [@elapsed interpret(bffibo, String(Char[i])) for i = 1:10],
        label = "Interpreted"
    )
    plot!(plot_title = "Time taken to calculate Fibonacci numbers")
    savefig("boolfuck-plot.svg")
end
