module PortableMinskyMachineNotation
export @pmmn_str, compile, load
using SparseArrays

struct PMMNError <: Exception
    msg::String
end

function inc(memory::SparseVector{I}, n, i::Integer = oneunit(I)) where {I<:Integer}
    memory[n+oneunit(n)] += i
    nothing
end

function dec(memory::SparseVector{I}, n, i::Integer = oneunit(I)) where {I<:Integer}
    n += oneunit(n)
    before = memory[n]
    memory[n] = max(zero(I), memory[n] - i)
    memory[n] != before
end

function input(io::IO, memory, n::Integer)
    if !eof(io)
        memory[n+oneunit(n)] += read(io, UInt8) + 1
    end
    nothing
end

function output(io::IO, memory, n::Integer)
    n += oneunit(n)
    if iswritable(io) && !iszero(memory[n])
        write(io, Char((memory[n] - 1) & 255))
    end
    memory[n] = zero(memory[n])
    nothing
end

function scan(source)
    (m.match for m in eachmatch(
        r"\d+|}|end|if|else|while|inc|dec|input|output",
        replace(source, r"(
            /\*(?:[^/]*|(?<!\*)/)*\*/|      # C style multiline comments
            \#=(?:[^#]*|(?<!\=)\#)=\#|      # Julia style multiline comments
            (\#|//).*                       # single line comments
        )"x => "")
    ))
end

parse(tokens) = parse(Iterators.Stateful(tokens))
parse(tokens::Iterators.Stateful) = commandlist(tokens)
parse(tokens::AbstractString) = parse(scan(tokens))

function expect(value::AbstractString, token::AbstractString)
    if token != value
        throw(PMMNError("Expected '$(value)', but got '$(token)'."))
    end
    token
end

function expect(value::AbstractVector, token::AbstractString)
    if !(token in value)
        throw(PMMNError("Expected '$(first(value))', but got '$(token)'."))
    end
    token
end

expect(value, tokens) = expect(value, popfirst!(tokens))

function commandlist(tokens)
    result = Expr[]
    while !isempty(tokens) && peek(tokens) != "}" && peek(tokens) != "end"
        push!(result, command(tokens))
    end
    if isempty(result)
        throw(PMMNError("Expected a command list, but found nothing."))
    end
    Expr(:block, result...)
end

function command(tokens, token = popfirst!(tokens))
    if token == "inc" || token == "dec"
        expr = Expr(:call, Symbol(token), :memory, Base.parse(Int, popfirst!(tokens)))
        if all(isdigit, peek(tokens))
            push!(expr.args, Base.parse(Int, popfirst!(tokens)))
        end
        expr
    elseif token == "if"
        condition = command(tokens, expect("dec", token))
        ifblock = block(tokens)
        if peek(tokens) == "else"
            Expr(:if, condition, ifblock, block(tokens))
        else
            Expr(:if, condition, ifblock)
        end
    elseif token == "while"
        condition = command(tokens, expect("dec", tokens))
        whileblock = block(tokens)
        Expr(:while, condition, whileblock)
    elseif token == "input" || token == "output"
        Expr(
            :call,
            Symbol(token),
            Symbol(replace(token, "put" => "")),
            :memory,
            Base.parse(Int, popfirst!(tokens))
        )
    else
        PMMNError("Unexpected token: $(token)")
    end
end

function block(tokens)
    expr = commandlist(tokens)
    expect(["}", "end"], tokens)
    expr
end

function compile(commands::Expr)
    fn = :(
        function (in = stdin; out = IOBuffer())
            if in isa AbstractString
                in = IOBuffer(in)
            end
            memory = spzeros(BigInt, 2000000000)
        end
    )
    push!(
        last(fn.args).args,
        commands,
        :(
            if out != stdout
                readchomp(seekstart(out))
            end
        )
    )
    eval(fn)
end

"""

    compile(str::AbstractString)

Compiles a string containing a Portable Minsky Machine Notation program.
"""
compile(str::AbstractString) = compile(parse(str))

"""

    pmmn""

A convenience macro for writing Portable Minsky Machine Notation.
"""
macro pmmn_str(str)
    :(compile($(str)))
end

"""

    load(filepath::AbstractString)

Load a Minsky machine from the specified file.
"""
load(filepath::AbstractString) = compile(readchomp(filepath))

end # module
