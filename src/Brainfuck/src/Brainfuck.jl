module BrainFuck
using SparseArrays
export @bf_str, compile, interpret

"""

    bracketindices(tokens)

Returns a Dict of the indices of square brackets and their corresponding matching bracket.
"""
function bracketindices(tokens)
    stack = []
    bracketpairs = Dict{Int,Int}()
    for (index, token) in Iterators.enumerate(tokens)
        if token == '['
            push!(stack, index)
        elseif token == ']'
            if isempty(stack)
                throw(ArgumentError("Unmatched ']' at position $(index)."))
            end
            otherindex = pop!(stack)
            push!(bracketpairs, index => otherindex, otherindex => index)
        end
    end
    if !isempty(stack)
        throw(ArgumentError(
            "Unmatched '[' at position$(length(stack) > 1 ? "s" : "") $(join(stack, ", ", " and "))."
        ))
    end
    bracketpairs
end

"""

    clean(code::AbstractString)

Strips out all non-Brainfuck characters from the given string.
"""
clean(code::AbstractString) = replace(code, r"[^\-+,.<>[\]]" => "")

"""

    interpret(code; kwargs...)

Interpret the given string as Brainfuck `code`.

## Keyword arguments

- `memorysize::Integer` How many bytes to allocate for memory, default is `30000`.
- `input::Union{AbstractString,IO}` The string or buffer which the `,` command reads from.
    Defaults to `stdin`.
- `output::Union{IO,Type{String}}` The buffer which the `.` command write to. Returns the
    output as a string if `String` is passed as to `output`. Defaults to `stdout`.
"""
function interpret(code;
    memorysize::Integer = 30000,
    input::Union{AbstractString,IO} = stdin,
    output::Union{IO,Type{String}} = stdout
)
    tokens = clean(code)
    brackets = bracketindices(tokens)
    memory = spzeros(UInt8, memorysize)
    pointer = 1
    i = 1
    if input isa AbstractString
        input = IOBuffer(input)
    end
    returnstring = output isa Type{String}
    if returnstring
        output = IOBuffer()
    end
    while i <= length(tokens)
        token = tokens[i]
        if token == '-'
            memory[pointer] -= 0x01
        elseif token == '+'
            memory[pointer] += 0x01
        elseif token == '<'
            pointer = max(1, pointer - 1)
        elseif token == '>'
            pointer = min(memorysize, pointer + 1)
        elseif token == ','
            if !eof(input)
                skipchars(c -> c == 0x0d && peek(input) == 0x0a, input)
                memory[pointer] = read(input, UInt8)
            end
        elseif token == '.'
            print(output, Char(memory[pointer]))
        elseif token == '['
            if iszero(memory[pointer])
                i = brackets[i]
            end
        elseif token == ']'
            if !iszero(memory[pointer])
                i = brackets[i]
            end
        end
        i += 1
    end
    if returnstring
        String(take!(output))
    end
end

"""

    compile(code)

Compiles the BrainFuck code to a Julia function. The returned function has the same
keywords arguments as `interpret(code)`.
"""
compile(code) = eval(expr(code))

"""

    bf"+++++++++++++++++++++."

Defines a BrainFuck program.

## Example

```jldoctest
julia> helloworld = bf"\""
    ++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>
    ---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
"\"";

julia> helloworld()
Hello World!

julia> helloworld(output = String)
"Hello World!\\n"

```
"""
macro bf_str(code)
    :(compile($code))
end

"""
Compiles the BrainFuck code to a Julia expr which will `eval` into a function.
"""
function expr(code)
    stack = [quote
        if input isa AbstractString
            input = IOBuffer(input)
        end
        returnstring = output isa Type{String}
        if returnstring
            output = IOBuffer()
        end
        pointer = 1
        memory = spzeros(UInt8, memorysize)
    end]
    tokens = Iterators.Stateful(clean(code))
    for token in tokens
        if occursin(token, "+-")
            i = token == '+' ? 0x01 : -0x01
            while occursin(peek(tokens), "+-")
                i += (popfirst!(tokens) == '+' ? 0x01 : -0x01)
            end
            push!(stack[end].args, :(memory[pointer] += $i))
        elseif occursin(token, "<>")
            i = token == '>' ? 1 : -1
            while occursin(peek(tokens), "<>")
                i += (popfirst!(tokens) == '>' ? 1 : -1)
            end
            push!(stack[end].args, :(pointer = clamp(pointer + $i, 1:memorysize)))
        elseif token == ','
            push!(stack[end].args, :(
                if !eof(input)
                    skipchars(c -> c == 0x0d && peek(input) == 0x0a, input)
                    memory[pointer] = read(input, UInt8)
                end
            ))
        elseif token == '.'
            push!(stack[end].args, :(print(output, Char(memory[pointer]))))
        elseif token == '['
            loop = Expr(:while, :(!iszero(memory[pointer])), Expr(:block))
            push!(stack[end].args, loop)
            push!(stack, loop.args[end])
        elseif token == ']'
            if length(stack) == 1
                throw(ArgumentError("Unmatched ']'."))
            end
            pop!(stack)
        end
    end
    if length(stack) != 1
        throw(ArgumentError("Unmatched '['."))
    end
    push!(stack[end].args, :(
        if returnstring
            String(take!(output))
        end
    ))
    Expr(
        :function,
        :((;
            memorysize::Integer = 30000,
            input::Union{AbstractString,IO} = stdin,
            output::Union{IO,Type{String}} = stdout
        )),
        only(stack)
    )
end

end # module
