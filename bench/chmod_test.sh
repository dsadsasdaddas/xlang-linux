#!/usr/bin/env bash
# Test chmod.x: octal mode + symbolic mode (u+x, go-w, a=r) + multiple files.
# Usage: chmod_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/chmod.x -o build/chmod.c >/dev/null 2>&1; cc -O2 -o /tmp/xchmod build/chmod.c
C=/tmp/xchmod
ROOT="$(mktemp -d)"

echo "== chmod octal mode"
touch "$ROOT/a"
/tmp/xchmod 755 "$ROOT/a"
actual=$(stat -c '%a' "$ROOT/a" 2>/dev/null)
if [ "$actual" = "755" ]; then echo "  ok   chmod 755"; PASS=$((PASS+1)); else echo "  FAIL 755 (got $actual)"; FAIL=$((FAIL+1)); fi

touch "$ROOT/b"
/tmp/xchmod 644 "$ROOT/b"
actual2=$(stat -c '%a' "$ROOT/b" 2>/dev/null)
if [ "$actual2" = "644" ]; then echo "  ok   chmod 644"; PASS=$((PASS+1)); else echo "  FAIL 644 (got $actual2)"; FAIL=$((FAIL+1)); fi

echo "== chmod symbolic mode"
touch "$ROOT/c" && chmod 644 "$ROOT/c"
/tmp/xchmod u+x "$ROOT/c"
actual3=$(stat -c '%a' "$ROOT/c" 2>/dev/null)
if [ "$actual3" = "744" ]; then echo "  ok   u+x"; PASS=$((PASS+1)); else echo "  FAIL u+x (got $actual3)"; FAIL=$((FAIL+1)); fi

touch "$ROOT/d" && chmod 777 "$ROOT/d"
/tmp/xchmod go-w "$ROOT/d"
actual4=$(stat -c '%a' "$ROOT/d" 2>/dev/null)
if [ "$actual4" = "755" ]; then echo "  ok   go-w"; PASS=$((PASS+1)); else echo "  FAIL go-w (got $actual4)"; FAIL=$((FAIL+1)); fi

touch "$ROOT/e" && chmod 777 "$ROOT/e"
/tmp/xchmod a=r "$ROOT/e"
actual5=$(stat -c '%a' "$ROOT/e" 2>/dev/null)
if [ "$actual5" = "444" ]; then echo "  ok   a=r"; PASS=$((PASS+1)); else echo "  FAIL a=r (got $actual5)"; FAIL=$((FAIL+1)); fi

echo "== multiple files"
touch "$ROOT/f1" "$ROOT/f2"
/tmp/xchmod 600 "$ROOT/f1" "$ROOT/f2"
a6=$(stat -c '%a' "$ROOT/f1" 2>/dev/null)
a7=$(stat -c '%a' "$ROOT/f2" 2>/dev/null)
if [ "$a6" = "600" ] && [ "$a7" = "600" ]; then echo "  ok   multi-file"; PASS=$((PASS+1)); else echo "  FAIL multi ($a6 $a7)"; FAIL=$((FAIL+1)); fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
