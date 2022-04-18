"""

    Parsers

Generate regex parsers from grammars.

## Exports

- `wsn_str` The `wsn""` macro for generating grammars in Wirth Syntax Notation.

"""
module Parsers
export wsn_str

struct Grammar
    regex::Regex
    rules::Dict{Symbol,Regex}
    Grammar(regex::Regex) = new(regex, Dict{Symbol,Regex}())
end

function Base.getindex(grammar::Grammar, name::Symbol)
    get!(grammar.rules, name) do
        if name in keys(grammar)
            grammar.rules[name] = Regex(
                "$(grammar.regex.pattern)(?&$(name))",
                grammar.regex.compile_options,
                grammar.regex.match_options
            )
        else
            throw(ArgumentError("$(name) is not a named group of the grammar."))
        end
    end
end

function Base.keys(grammar::Grammar)
    Symbol.(filter(Base.Fix2(isa, String), keys(match(grammar.regex, ""))))
end

function Base.match(grammar::Grammar, symbol::Symbol, str::AbstractString, idx::Integer=firstindex(str), addopts...)
    match(grammar[symbol], str, idx, addopts...).match
end

function Base.eachmatch(grammar::Grammar, symbol::Symbol, str::AbstractString; overlap::Bool=false)
    (m.match for m in eachmatch(grammar[symbol], str; overlap=overlap))
end

Base.show(io::IO, grammar::Grammar) = print(io, "Grammar(", grammar.regex, ")")

"""

    @wsn""

Convert a grammar written in Wirth Syntax Notation to a `Grammar`.

- `upper`   `[A-Z]`                 uppercase letters
- `lower`   `[a-z]`	                lowercase letters
- `alpha`   `[A-Za-z]`	            upper- and lowercase letters
- `digit`   `[0-9]`	                digits
- `xdigit`  `[0-9A-Fa-f]`	        hexadecimal digits
- `alnum`   `[A-Za-z0-9]`	        digits, upper- and lowercase letters
- `punct`  	                        punctuation (all graphic characters except letters and digits)
- `blank`   `[ \\t]`	            space and tab characters only
- `space`   `[ \\t\\n\\r\\f\\v]`	blank (whitespace) characters
- `cntrl`  	                        control characters
- `graph`   `[^ [:cntrl:]]`	        graphic characters (all characters which have graphic representation)
- `print`   `[[:graph:] ]`	        graphic characters and space
- `word`    `[[:alnum:]_]`	        alphanumeric characters with underscore character _, meaning alnum + _.
- `vspace`  `\\r\\n?|\\n`           vertical whitespace characters (cr, lf or crlf)
"""
macro wsn_str(grammar)
    :(Parser.Grammar(Parser.wsn(grammar)))
end

wsngrammar = Grammar(r"""
(?(DEFINE) # Wirth Syntax Notation
(?<syntax>
    ^(?>\s*) (?> (?&production) \s* )* $ )
(?<production>
    (?&identifier) (?>\s*) (::)?= (?&expression) [\.;] )
(?<expression>
    (?&term) (?> \| (?&term) )* )
(?<term>
    (?&factor) ( ,? (?&factor) )* )
(?<factor> (?>\s*) (?>
    \[ (?&expression) \]
    | \( (?&expression) \)
    | { (?&expression) }
    | (?&literal)
    | (?&identifier) ) (?>\s*) )
(?<identifier>
    (?<rawid>[[:alpha:]_][[:alnum:]_]*)
    | <(?&rawid)> )
(?<literal>
    " ( [^"] | "" )* " )
(?<tokens>
    (?&literal) | ::= | [={}[\](){}|.;] | (?&identifier) )
)"""x)

wsn(str::AbstractString) = Grammar(Regex(syntax(wsngrammar, str)))

function syntax(grammar::Grammar, str::AbstractString)
    """(?(DEFINE)$(join(production(grammar, eachmatch(grammar, :production, str))))"""
end

production(grammar::Grammar, iter) = (production(grammar, match) for match in iter)
function production(grammar::Grammar, str::AbstractString)
    rstrip(c -> isspace(c) || c == '.', str)
    id, expr = split(str, r"\s*=\s*", limit=2)
    id = identifier(grammar, id)
    "(?<$(id)>" * join(
        expression(grammar, eachmatch(grammar, :expression, expr)),
        '|') * ")"
end

expression(grammar::Grammar, iter) = (expression(grammar, match) for match in iter)
function expression(grammar::Grammar, str::AbstractString)
    join(term(grammar, eachmatch(grammar, :term, str)), '|')
end

term(grammar::Grammar, iter) = (term(grammar, match) for match in iter)
function term(grammar::Grammar, str::AbstractString)
    join(factor(grammar, eachmatch(grammar, :factor, str)))
end

factor(grammar::Grammar, iter) = (factor(grammar, match) for match in iter)
function factor(grammar::Grammar, str::AbstractString)
    str = strip(str)
    if startswith(str, '"')
        literal(grammar, str)
    elseif startswith(str, r"[[({]")
        "(" * expression(grammar, str[begin+1:end-1]) * (
            if startswith(str, '[')
                ")?"
            elseif startswith(str, '{')
                ")*"
            else
                ")"
            end
        )
    elseif str in (
        "upper", "lower", "alpha", "digit", "xdigit", "alnum",
        "punct", "blank", "space", "cntrl", "graph", "print", "word"
    )
        "[[:$(str):]]"
    elseif str == "vspace"
        "(\\r*\\n?|\\n)"
    else
        "(?&$(identifier(grammar, str)))"
    end
end

function literal(::Grammar, str::AbstractString)
    "\\Q$(replace(str[begin+1:end-1], "\"\"" => "\""))\\E"
end

function identifier(::Grammar, str::AbstractString)
    strip(in("<> \t"), str)
end

end # module
