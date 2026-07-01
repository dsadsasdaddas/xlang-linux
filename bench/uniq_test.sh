#!/usr/bin/env bash
# Test uniq.x vs GNU uniq: default, -c, -d, -u.
# Usage: uniq_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/uniq.x -o build/uniq.c >/dev/null 2>&1; cc -O2 -o /tmp/xuniq build/uniq.c
U=/tmp/xuniq
INPUT=$'a\na\nb\nc\nc\nc\nd\n'

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$INPUT" | "$U" "$@" 2>/dev/null)
    b=$(printf '%s' "$INPUT" | uniq "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== uniq vs GNU"
cmp_gnu "default"
cmp_gnu "-c"  -c
cmp_gnu "-d"  -d
cmp_gnu "-u"  -u

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
