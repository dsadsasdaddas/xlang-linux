#!/usr/bin/env bash
# Test comm.x vs GNU comm: default, -1, -2, -3, -12, -23.
# Usage: comm_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/comm.x -o build/comm.c >/dev/null 2>&1; cc -O2 -o /tmp/xcomm build/comm.c
C=/tmp/xcomm
ROOT="$(mktemp -d)"
printf 'a\nb\nd\n' > "$ROOT/f1"
printf 'b\nc\nd\n' > "$ROOT/f2"

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$("$C" "$@" "$ROOT/f1" "$ROOT/f2" 2>/dev/null)
    b=$(comm "$@" "$ROOT/f1" "$ROOT/f2" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== comm vs GNU"
cmp_gnu "default"
cmp_gnu "-1"  -1
cmp_gnu "-2"  -2
cmp_gnu "-3"  -3
cmp_gnu "-12" -12
cmp_gnu "-23" -23
cmp_gnu "-13" -13

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
