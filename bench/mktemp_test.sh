#!/usr/bin/env bash
# Test mktemp.x: file creation, -d directory, TEMPLATE expansion.
# Usage: mktemp_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/mktemp.x -o build/mktemp.c >/dev/null 2>&1; cc -O2 -o /tmp/xmktemp build/mktemp.c
M=/tmp/xmktemp

echo "== mktemp file"
f=$("$M" 2>/dev/null)
if [ -f "$f" ]; then echo "  ok   creates file [$f]"; PASS=$((PASS+1)); else echo "  FAIL file"; FAIL=$((FAIL+1)); fi
rm -f "$f" 2>/dev/null

echo "== mktemp -d directory"
d=$("$M" -d 2>/dev/null)
if [ -d "$d" ]; then echo "  ok   creates dir [$d]"; PASS=$((PASS+1)); else echo "  FAIL dir"; FAIL=$((FAIL+1)); fi
rmdir "$d" 2>/dev/null

echo "== mktemp template expansion"
t=$("$M" /tmp/xlang_test_XXXXXX 2>/dev/null)
if echo "$t" | grep -q '^/tmp/xlang_test_[0-9]\{6\}$'; then
    echo "  ok   template X's replaced [$t]"; PASS=$((PASS+1))
else
    echo "  FAIL template [$t]"; FAIL=$((FAIL+1))
fi
rm -f "$t" 2>/dev/null

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
