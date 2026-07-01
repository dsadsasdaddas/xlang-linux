#!/usr/bin/env bash
# Test nl.x vs GNU nl: basic numbering, -w (width), -s (separator).
# Usage: nl_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/nl.x -o build/nl.c >/dev/null 2>&1; cc -O2 -o /tmp/xnl build/nl.c
N=/tmp/xnl
INPUT=$'line1\nline2\nline3\n'

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$INPUT" | "$N" "$@" 2>/dev/null)
    b=$(printf '%s' "$INPUT" | nl "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== nl vs GNU"
cmp_gnu "default -ba"
cmp_gnu "-w3"      -w3
cmp_gnu "-s ' '"   -s ' '
cmp_gnu "-w2 -s ':'" -w2 -s ':'

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
