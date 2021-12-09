# Portable Minsky Machine Notation

A compiler for a flexible superset of [Portable Minsky Machine Notation](https://esolangs.org/wiki/Portable_Minsky_Machine_Notation) in Julia.

## Features

- SparseVector-based memory, uses only as much memory as your program uses while still supporting the full range of counters.
- `inc_by`, `dec_by`, `input` and `output` extended functions.
- In addition to C-style multiline comments `/*...*/`, supports Julia-style multiline comments `#=...=#` and single line comments, which can begin with `//`  or `#`.
- Semicolons and commas aren't needed and are treated as whitespace, but you can use them if you want to keep your code portable to other implementations of PMMN.
- Parens and braces are also optional, except for closing braces. The closing brace can be replaced with the `end` keyword, making code which looks more Julian.

## Examples

```julia
julia> standardmachine = pmmn"""
/* Compiles the core grammar and extensions */
inc_by(0, 88);
inc_by(1, 112);
inc_by(2, 120);
inc_by(3, 34);
output(0);
output(1);
output(2);
output(3);
""";

julia> standardmachine()
"Wow!"

julia> standardmachine(out = stdout)
Wow!

julia> julianmachine = pmmn"""
# supports Julia style syntax too
inc(1, 2)
while dec(1)
    input(0)
    output(0)
end
""";

julia> julianmachine(":D")
":D"

julia> chunkybaconmachine = pmmn"""
# or pretend it's Ruby if that's your jam
inc 1, 8
while dec 1
  input 0
  dec 0
  output 0
end
"""

julia> chunkybaconmachine("IBM.:111")
"HAL-9000"

julia> load("path/to/program.txt")()
"Load programs from files!"
```

## Use

In Julia, run:

```julia
using Pkg
Pkg.add(url = "https://github.com/stellartux/PortableMinskyMachineNotation/")
using .PortableMinskyMachineNotation
yourprogram = pmmn"..."
```
