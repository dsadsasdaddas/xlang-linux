#!/usr/bin/env bash
# Test unexpand.x vs GNU unexpand: default (leading only), -a (all), -t N.
# Usage: unexpand_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/unexpand.x -o build/unexpand.c >/dev/null 2>&1; cc -O2 -o /tmp/xunexpand build/unexpand.c
U=/tmp/xunexpand

cmp_gnu() {
    local label="$1"; shift
    local input="$1"; shift
    local a b
    a=$(printf '%s' "$input" | "$U" "$@" 2>/dev/null)
    b=$(printf '%s' "$input" | unexpand "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(printf '%s' "$a" | od -An -tx1 | tr -d ' \n')]"; echo "       g:[$(printf '%s' "$b" | od -An -tx1 | tr -d ' \n')]"; FAIL=$((FAIL+1)); fi
}

echo "== unexpand vs GNU"
cmp_gnu "default leading" $'        hello'
cmp_gnu "-a all"          -a $'        hello         world'
cmp_gnu "-t 4"      -a -t 4 $'    a       b'
cmp_gnu "no spaces"         'no spaces'

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
