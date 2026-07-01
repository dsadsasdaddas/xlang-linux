#!/usr/bin/env bash
# Test cat.x vs GNU cat: plain (backward compat), -n, -A, -s, -nA, multi-file.
# Usage: cat_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/cat.x -o build/cat.c >/dev/null 2>&1; cc -O2 -o /tmp/xcat build/cat.c
C=/tmp/xcat
ROOT="$(mktemp -d)"
printf 'a\n\n\nb\tc\nd\n' > "$ROOT/f1"
printf 'x\ny\n' > "$ROOT/f2"

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(cd "$ROOT" && "$C" "$@" 2>/dev/null)
    b=$(cd "$ROOT" && cat "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== cat vs GNU"
cmp_gnu "plain"    f1
cmp_gnu "-n"       -n f1
cmp_gnu "-b"       -b f1
cmp_gnu "-A"       -A f1
cmp_gnu "-s"       -s f1
cmp_gnu "-nA"      -nA f1
cmp_gnu "multi"    f1 f2
cmp_gnu "-n multi" -n f1 f2

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
