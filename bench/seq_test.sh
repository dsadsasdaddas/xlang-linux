#!/usr/bin/env bash
# Test seq.x vs GNU seq: integer and float modes.
# Usage: seq_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/seq.x -o build/seq.c >/dev/null 2>&1; cc -O2 -o /tmp/xseq build/seq.c
S=/tmp/xseq

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$("$S" "$@" 2>/dev/null)
    b=$(seq "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== seq vs GNU"
cmp_gnu "int 5"           5
cmp_gnu "int 2 5"         2 5
cmp_gnu "int step"        1 2 10
cmp_gnu "int countdown"   10 -2 0
cmp_gnu "float 1 0.5 3"   1 0.5 3
cmp_gnu "float 0.1 step"  0 0.1 0.5
cmp_gnu "float countdown" 3 -0.5 1

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
