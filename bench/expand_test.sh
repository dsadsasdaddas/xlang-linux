#!/usr/bin/env bash
# Test expand.x vs GNU expand: default tab stops, -t custom, mixed.
# Usage: expand_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/expand.x -o build/expand.c >/dev/null 2>&1; cc -O2 -o /tmp/xexpand build/expand.c
E=/tmp/xexpand

cmp_gnu() {
    local label="$1"; shift
    local input="$1"; shift
    local a b
    a=$(printf '%s' "$input" | "$E" "$@" 2>/dev/null)
    b=$(printf '%s' "$input" | expand "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$a]"; echo "       g:[$b]"; FAIL=$((FAIL+1)); fi
}

echo "== expand vs GNU"
cmp_gnu "default tab"    $'a\tb\tc'
cmp_gnu "-t 4"    -t 4   $'a\tb\tc'
cmp_gnu "-t 2"    -t 2   $'a\tb\tc'
cmp_gnu "multiline" -t 4 $'a\tb\n\t\tx'
cmp_gnu "no tabs"         'no tabs here'

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
