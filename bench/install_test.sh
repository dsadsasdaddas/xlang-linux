#!/usr/bin/env bash
# Test install.x: copy + -m mode + -d dirs + multi-file.
# Usage: install_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/install.x -o build/install.c >/dev/null 2>&1; cc -O2 -o /tmp/xinstall build/install.c
I=/tmp/xinstall
ROOT="$(mktemp -d)"
printf 'data' > "$ROOT/src1"
printf 'more' > "$ROOT/src2"

echo "== install single"
/tmp/xinstall "$ROOT/src1" "$ROOT/dst1"
if [ -f "$ROOT/dst1" ] && [ "$(cat "$ROOT/dst1")" = "data" ]; then
    echo "  ok   copy"; PASS=$((PASS+1))
else
    echo "  FAIL copy"; FAIL=$((FAIL+1))
fi

echo "== install -m 755"
/tmp/xinstall -m 755 "$ROOT/src1" "$ROOT/dst2"
mode=$(stat -c '%a' "$ROOT/dst2" 2>/dev/null)
if [ "$mode" = "755" ]; then
    echo "  ok   mode 755"; PASS=$((PASS+1))
else
    echo "  FAIL mode (got $mode)"; FAIL=$((FAIL+1))
fi

echo "== install multi into dir"
mkdir "$ROOT/destdir"
/tmp/xinstall "$ROOT/src1" "$ROOT/src2" "$ROOT/destdir"
if [ -f "$ROOT/destdir/src1" ] && [ -f "$ROOT/destdir/src2" ]; then
    echo "  ok   multi-file"; PASS=$((PASS+1))
else
    echo "  FAIL multi"; FAIL=$((FAIL+1))
fi

echo "== install -d"
/tmp/xinstall -d "$ROOT/newdir1/sub"
if [ -d "$ROOT/newdir1/sub" ]; then
    echo "  ok   -d creates dirs"; PASS=$((PASS+1))
else
    echo "  FAIL -d"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
