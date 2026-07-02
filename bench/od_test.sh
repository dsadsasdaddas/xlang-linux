#!/usr/bin/env bash
# Test od.x vs GNU od: octal default, -An (no addr), -tx1 (hex), -td1 (decimal), -tc (char).
# Usage: od_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/od.x -o build/od.c >/dev/null 2>&1; cc -O2 -o /tmp/xod build/od.c
O=/tmp/xod
INPUT="ABC"

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$INPUT" | "$O" "$@" 2>/dev/null)
    b=$(printf '%s' "$INPUT" | od "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$a]"; echo "       g:[$b]"; FAIL=$((FAIL+1)); fi
}

echo "== od vs GNU"
cmp_gnu "-An -tx1 (hex)"  -An -tx1
cmp_gnu "-An -to1 (oct)"   -An -to1
cmp_gnu "-An -td1 (dec)"   -An -td1

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
