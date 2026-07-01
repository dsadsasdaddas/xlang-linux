#!/usr/bin/env bash
# Test cp.x: binary-safe copy (NUL bytes), recursive -r (tree matches), and
# multiple files into a directory.
#
# Usage: cp_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/cp.x -o build/cp.c >/dev/null 2>&1; cc -O2 -o /tmp/xcp build/cp.c
C=/tmp/xcp
ROOT="$(mktemp -d)"

echo "== binary-safe copy (NUL bytes)"
head -c 5000 /dev/urandom > "$ROOT/bin"
"$C" "$ROOT/bin" "$ROOT/bin2"
if cmp -s "$ROOT/bin" "$ROOT/bin2"; then echo "  ok   binary copy byte-identical"; PASS=$((PASS+1)); else echo "  FAIL binary copy"; FAIL=$((FAIL+1)); fi

echo "== recursive copy (-r)"
mkdir -p "$ROOT/tree/sub"
printf 'a\n' > "$ROOT/tree/f1"
printf 'b\n' > "$ROOT/tree/sub/f2"
"$C" -r "$ROOT/tree" "$ROOT/tree2"
if diff -r "$ROOT/tree" "$ROOT/tree2" >/dev/null 2>&1; then echo "  ok   recursive copy matches (diff -r clean)"; PASS=$((PASS+1)); else echo "  FAIL recursive copy"; FAIL=$((FAIL+1)); fi

echo "== multiple files into a directory"
mkdir "$ROOT/dest"
printf '1\n' > "$ROOT/x"
printf '2\n' > "$ROOT/y"
"$C" "$ROOT/x" "$ROOT/y" "$ROOT/dest"
if [ -f "$ROOT/dest/x" ] && [ -f "$ROOT/dest/y" ] && cmp -s "$ROOT/x" "$ROOT/dest/x"; then
    echo "  ok   multi-file into dir"; PASS=$((PASS+1))
else
    echo "  FAIL multi-file into dir"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
