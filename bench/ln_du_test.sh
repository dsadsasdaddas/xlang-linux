#!/usr/bin/env bash
# Test ln.x and du.x: symlink creation + recursive byte count.
# Usage: ln_du_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/ln.x  -o build/ln.c  >/dev/null 2>&1; cc -O2 -o /tmp/xln  build/ln.c
"$XLANGC" c coreutils/du.x  -o build/du.c  >/dev/null 2>&1; cc -O2 -o /tmp/xdu  build/du.c

ROOT="$(mktemp -d)"
printf 'hello' > "$ROOT/file1"
printf 'world' > "$ROOT/file2"

echo "== ln -s"
/tmp/xln -s "$ROOT/file1" "$ROOT/link1"
if [ -L "$ROOT/link1" ] && [ "$(cat "$ROOT/link1")" = "hello" ]; then
    echo "  ok   symlink works"; PASS=$((PASS+1))
else
    echo "  FAIL symlink"; FAIL=$((FAIL+1))
fi

echo "== ln hard link"
/tmp/xln "$ROOT/file2" "$ROOT/hard2"
if [ -f "$ROOT/hard2" ] && [ "$(cat "$ROOT/hard2")" = "world" ]; then
    echo "  ok   hard link works"; PASS=$((PASS+1))
else
    echo "  FAIL hard link"; FAIL=$((FAIL+1))
fi

echo "== du"
out=$(/tmp/xdu "$ROOT" 2>/dev/null | awk '{print $1}')
if [ "$out" -ge 10 ]; then
    echo "  ok   du totals bytes ($out)"; PASS=$((PASS+1))
else
    echo "  FAIL du (got $out, expected $expected)"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
