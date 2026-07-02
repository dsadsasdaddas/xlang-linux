#!/usr/bin/env bash
# Test tac, rev, fold vs GNU. Combined test suite for these three simple tools.
# Usage: text_tools_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/tac.x   -o build/tac.c   >/dev/null 2>&1; cc -O2 -o /tmp/xtac   build/tac.c
"$XLANGC" c coreutils/rev.x   -o build/rev.c   >/dev/null 2>&1; cc -O2 -o /tmp/xrev   build/rev.c
"$XLANGC" c coreutils/fold.x  -o build/fold.c  >/dev/null 2>&1; cc -O2 -o /tmp/xfold  build/fold.c
INPUT=$'one\ntwo\nthree\nfour\n'

cmp_gnu() {
    local tool="$1" xtool="$2" label="$3"; shift 3
    local a b
    a=$(printf '%s' "$INPUT" | "$xtool" "$@" 2>/dev/null)
    b=$(printf '%s' "$INPUT" | "$tool" "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== tac vs GNU"
cmp_gnu tac /tmp/xtac "tac default"

echo "== rev vs GNU"
cmp_gnu rev /tmp/xrev "rev default"

echo "== fold vs GNU"
cmp_gnu fold /tmp/xfold "fold default"
cmp_gnu fold /tmp/xfold "fold -w 3" -w 3

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
