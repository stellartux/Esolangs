#!/usr/bin/awk -f

BEGIN {
    print "#include <stdio.h>\n"
    print "int main() {"
    print "    char c = 0;"
    print "    char m = 0;"
    print "Label0:" 
}

{ gsub(/[\r\n]+$/, "") }

/^[*YN]/ {
    do {
        if ($0 ~ /^\*/) {
            print("Label" ++last_label ":")
        } else {
            print("    if (m == '" substr($0, 1, 1) "')")
        }
        $0 = substr($0, 2)
    } while ($0 ~ /^[*YN]/)
}

# A: { input one character from the terminal keyboard }
/^A:/ { 
    last_accept = NR
    print "Accept" NR ":"
    # print "    do { c = getchar(); } while (c == '\\r' || c == '\\n');"
    print "    c = getchar(); getchar();"
    next
}

# M:x { compare x to the last input character and set match flag to Y if equal, N if not equal. }
/^M:/ {
    print "    m = c == '" substr($0, 3, 1) "' ? 'Y' : 'N';"
    next
}

# J:1-9 { jump ahead x labels }
/^J:[1-9]/ {
    print "    goto Label" (last_label + substr($0, 3, 1)) ";"
    next
}

# J:0? { jump back to the last A statement }
/^J:0?/ {
    print "    goto Accept" last_accept ";"
    next
}

# S: { exit }
/^S:[ \t]*$/ { print "    return 0;"; next }

# T:text { display text on the terminal }
/^T:/ { $0 = substr($0, 3) }

# fallback, print the line if no command was recognised
{
    gsub("\"", "\\\"")
    gsub("\r", "\\r")
    print("    printf(\"" $0 "\\n\");")
}

END { 
    print "    return 0;"
    print "}"
}
