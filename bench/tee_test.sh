#!/usr/bin/env bash
# Test tee.x vs GNU tee: basic write, append, multiple files.
# Usage: tee_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/tee.x -o build/tee.c >/dev/null 2>&1; cc -O2 -o /tmp/xtee build/tee.c
T=/tmp/xtee
ROOT="$(mktemp -d)"

echo "== tee vs GNU"
# Basic: stdin → file + stdout
expected="hello"
actual=$(printf 'hello' | "$T" "$ROOT/a" 2>/dev/null)
file_content=$(cat "$ROOT/a")
if [ "$actual" = "$expected" ] && [ "$file_content" = "$expected" ]; then
    echo "  ok   basic (stdout + file)"; PASS=$((PASS+1))
else
    echo "  FAIL basic (stdout=[$actual] file=[$file_content])"; FAIL=$((FAIL+1))
fi

# Multiple files
printf 'multi' | "$T" "$ROOT/b" "$ROOT/c" >/dev/null 2>&1
if [ "$(cat "$ROOT/b")" = "multi" ] && [ "$(cat "$ROOT/c")" = "multi" ]; then
    echo "  ok   multiple files"; PASS=$((PASS+1))
else
    echo "  FAIL multiple files"; FAIL=$((FAIL+1))
fi

# Append
printf 'first' | "$T" "$ROOT/d" >/dev/null 2>&1
printf 'second' | "$T" -a "$ROOT/d" >/dev/null 2>&1
if [ "$(cat "$ROOT/d")" = "firstsecond" ]; then
    echo "  ok   append (-a)"; PASS=$((PASS+1))
else
    echo "  FAIL append (got [$(cat "$ROOT/d")])"; FAIL=$((FAIL+1))
fi

# Overwrite (no -a)
printf 'over' | "$T" "$ROOT/d" >/dev/null 2>&1
if [ "$(cat "$ROOT/d")" = "over" ]; then
    echo "  ok   overwrite (no -a)"; PASS=$((PASS+1))
else
    echo "  FAIL overwrite (got [$(cat "$ROOT/d")])"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
