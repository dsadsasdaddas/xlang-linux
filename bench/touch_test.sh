#!/usr/bin/env bash
# Test touch.x: create new file, preserve existing content, -c flag, multi-file.
# Usage: touch_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/touch.x -o build/touch.c >/dev/null 2>&1; cc -O2 -o /tmp/xtouch build/touch.c
T=/tmp/xtouch
ROOT="$(mktemp -d)"

echo "== touch new file"
/tmp/xtouch "$ROOT/new"
if [ -f "$ROOT/new" ]; then echo "  ok   creates new file"; PASS=$((PASS+1)); else echo "  FAIL new file"; FAIL=$((FAIL+1)); fi

echo "== touch preserves existing content"
printf 'important data' > "$ROOT/existing"
/tmp/xtouch "$ROOT/existing"
content=$(cat "$ROOT/existing")
if [ "$content" = "important data" ]; then echo "  ok   preserves content"; PASS=$((PASS+1)); else echo "  FAIL truncated [$content]"; FAIL=$((FAIL+1)); fi

echo "== touch -c nonexistent (no error, no create)"
/tmp/xtouch -c "$ROOT/nocreate"
if [ ! -f "$ROOT/nocreate" ]; then echo "  ok   -c does not create"; PASS=$((PASS+1)); else echo "  FAIL -c created file"; FAIL=$((FAIL+1)); fi

echo "== touch multiple files"
/tmp/xtouch "$ROOT/m1" "$ROOT/m2" "$ROOT/m3"
if [ -f "$ROOT/m1" ] && [ -f "$ROOT/m2" ] && [ -f "$ROOT/m3" ]; then
    echo "  ok   multi-file"; PASS=$((PASS+1))
else
    echo "  FAIL multi-file"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
