module Boolfuck
export compile, interpret

using .Base.Iterators

function brainfucktoboolfuck(brainfuck)
    commands = Dict((
        '+' => ">[>]+<[+<]>>>>>>>>>[+]<<<<<<<<<",
        '-' => ">>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+]<<<<<<<<<",
        '<' => "<<<<<<<<<",
        '>' => ">>>>>>>>>",
        ',' => ">,>,>,>,>,>,>,>,<<<<<<<<",
        '.' => ">;>;>;>;>;>;>;>;<<<<<<<<",
        '[' => ">>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+<<<<<<<<[>]+<[+<]",
        ']' => ">>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>]<[+<]"
    ))
    join(get(commands, command, "") for command in brainfuck)
end

"""Strip all non-Boolfuck characters from the code."""
clean(code::AbstractString)::String = replace(code, r"[^+,;<>[\]]+" => "")

"""Find the matching bracket [] in either direction."""
function matchbracket(code::AbstractString, pointer::Integer, char::Char)
    direction = char == '[' ? 1 : -1
    bracketcount = direction
    while !iszero(bracketcount)
        pointer += direction
        if code[pointer] == '['
            bracketcount += 1
        elseif code[pointer] == ']'
            bracketcount -= 1
        end
    end
    pointer
end

"""Converts a string of `Char`s to its bits as `Bool`s in little Endian order."""
function tobitstream(input)
    Iterators.Stateful(flatten((
        (bit == '1' for char in input for bit in reverse(bitstring(UInt8(char)))),
        repeated(false)
    )))
end

"""Convert a little Endian iterator of Bools to a string"""
function frombitstream(input)::String
    join(Char(sum(bit << (index - 1) for (index, bit) in enumerate(bits)))
         for bits in partition(input, 8))
end

function interpret(code::AbstractString, input::AbstractString = "")::String
    codepointer = 1
    memorypointer = 0
    memory = Dict{Int,Bool}()
    output = Bool[]
    code = clean(code)

    lefttoright = Dict{Int,Int}(
        index => matchbracket(code, index, char) for (index, char) in enumerate(code) if occursin(char, "[]")
    )
    righttoleft = Dict{Int,Int}(
        right => left for (left, right) in pairs(lefttoright)
    )

    inputbits = tobitstream(input)

    while codepointer <= lastindex(code)
        instr = code[codepointer]
        if instr == '+'
            endpointer = findnext(!=('+'), code, codepointer) - 1
            if iseven(endpointer - codepointer)
                memory[memorypointer] = !get(memory, memorypointer, false)
            end
            codepointer = endpointer
        elseif instr == ','
            memory[memorypointer] = popfirst!(inputbits)
        elseif instr == ';'
            push!(output, get!(memory, memorypointer, false))
        elseif instr == '[' && !get!(memory, memorypointer, false)
            codepointer = lefttoright[codepointer]
        elseif instr == ']' && get!(memory, memorypointer, false)
            codepointer = righttoleft[codepointer]
        else
            endpointer = findnext(!occursin("<>"), code, codepointer) - 1
            substr = view(code, codepointer:endpointer)
            memorypointer += count(==('>'), substr) - count(==('<'), substr)
            codepointer = endpointer
        end
        codepointer += 1
    end

    frombitstream(output)
end

function compile(code::AbstractString)::Function
    exprs = [:(function compiledboolfuck(input = "")::String
        inputbits = tobitstream(input)
        memorypointer = 0
        memory = Dict{Int,Bool}()
        output = Bool[]
    end)]

    symbolstack = []

    for match in eachmatch(r"(?:[,;\[\]]|[<>]+|\++)", code)
        instr = match.match[1]

        if instr == '+'
            if isodd(length(match.match))
                push!(exprs[end].args[2].args, :(memory[memorypointer] = !get(memory, memorypointer, false)))
            end

        elseif instr == ','
            push!(exprs[end].args[2].args, :(memory[memorypointer] = popfirst!(inputbits)))

        elseif instr == ';'
            push!(exprs[end].args[2].args, :(push!(output, get!(memory, memorypointer, false))))

        elseif instr == '['
            e = :(
                while get!(memory, memorypointer, false)
                end
            )
            push!(exprs[end].args[2].args, e)
            push!(exprs, e)

        elseif instr == ']'
            if length(exprs) == 1
                throw(ArgumentError("Unmatched ']'"))
            end
            pop!(exprs)

        elseif occursin(instr, "<>")
            x = count(==('>'), match.match) - count(==('<'), match.match)
            if !iszero(x)
                push!(exprs[end].args[2].args, :(memorypointer += $x))
            end
        end
    end

    if !isempty(symbolstack)
        throw(Error("$(length(symbolstack)) unmatched brackets"))
    end

    push!(exprs[end].args[2].args, :(frombitstream(output)))

    @info exprs

    eval(only(exprs))
end

# boolfuck = interpret
boolfuck = (code, input) -> compile(code)(input)

end
