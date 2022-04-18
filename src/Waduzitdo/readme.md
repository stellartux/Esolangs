# Waduzitdo

From [the September 1978 edition of Byte magazine](https://archive.org/details/byte-magazine-1978-09/page/n167/mode/2up?view=theater), it's Waduzitdo, a neat little programming language.

## Usage

Run the compiler with the following code. The awk script generates C code from the Waduzitdo source and feeds that to the C compiler.

```shell
awk -f compiler.awk $SRCFILENAME | cc -o $DESTFILENAME -xc -
```

## Language Description

Statement | Format     | What It Does
------------ | ---------- | ---
type | `T:text` | Display text on the terminal.
accept  | `A:` | Input one character from the terminal keyboard.
match | `M:x` | Compare `x` to the last input character and set match flag to `Y` if equal, `N` if not equal.
jump | `J:n` | if `n = 0` jump to last accept. if `n = 1` thru `9`, jump to nth program marker forward from the `J`.
stop | `S:` | Terminate program and return to text editor.
subroutine | `S:x` | Call user machine language program [requires modification].
conditionals  | `Y` | May precede any statement, execute following opcode if match flag is `Y`.
conditionals  | `N` | May precede any statement, execute following opcode if match flag is `N.`
program marker | `*` | May precede any statement, serves as *jump* destination.

## Examples

```waduzitdo
T:Hello, world!
```

See `nim.waduzitdo` for a larger example transcribed from the original documentation.
