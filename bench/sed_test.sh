#!/usr/bin/env bash
# Test sed.x vs GNU sed: single + multiple commands, -e, addresses, -n, literal
# ';' inside s///.
# Usage: sed_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/sed.x -o build/sed.c >/dev/null 2>&1; cc -O2 -o /tmp/xsed build/sed.c
S=/tmp/xsed
INPUT=$'banana\napple\ncherry\n'

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$INPUT" | "$S" "$@" 2>/dev/null)
    b=$(printf '%s' "$INPUT" | sed "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== sed vs GNU"
cmp_gnu "s global"           's/a/X/g'
cmp_gnu "two commands"       's/a/X/g; s/n/N/'
cmp_gnu "two -e"             -e 's/a/X/' -e 's/n/N/g'
cmp_gnu "delete line 2"      '2d'
cmp_gnu "print only line 2"  -n '2p'
cmp_gnu "addr range sub"     '1,2s/e/3/g'
cmp_gnu "literal ; in repl"  's/a/A;B/'

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
