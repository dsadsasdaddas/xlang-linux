#!/usr/bin/env bash
# Test dd.x: full binary copy (byte-identical), skip, and a throughput benchmark
# vs GNU dd.
#
# Usage: dd_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/dd.x -o build/dd.c >/dev/null 2>&1 || "$XLANGC" c coreutils/dd.x >/dev/null 2>&1
cc -O2 -o /tmp/xlang_dd build/dd.c
DD=/tmp/xlang_dd
ROOT="$(mktemp -d)"
head -c 100000 /dev/urandom > "$ROOT/bin"     # 100 KB binary (has NUL bytes)

echo "== full binary copy byte-identical"
"$DD" if="$ROOT/bin" of="$ROOT/copy" bs=4096
if cmp -s "$ROOT/bin" "$ROOT/copy"; then echo "  ok   copy byte-identical"; PASS=$((PASS+1)); else echo "  FAIL copy differs"; FAIL=$((FAIL+1)); fi

echo "== skip (skip first 1000 bytes)"
"$DD" if="$ROOT/bin" of="$ROOT/skipped" bs=1 skip=1000
tail -c +1001 "$ROOT/bin" > "$ROOT/expect_skip"
if cmp -s "$ROOT/skipped" "$ROOT/expect_skip"; then echo "  ok   skip correct"; PASS=$((PASS+1)); else echo "  FAIL skip"; FAIL=$((FAIL+1)); fi

echo "== throughput: 50 MB read, xlang dd vs GNU dd (3 runs, best)"
head -c 50000000 /dev/urandom > "$ROOT/big"
bestof() {  # bestof <cmd...> → best (min) of 3 runs in seconds (4 decimals)
    local b=""
    for _ in 1 2 3; do
        local t=$( { /usr/bin/time -f '%e' "$@" >/dev/null; } 2>&1 )
        b="${b}${t} "
    done
    printf '%s\n' $b | sort -n | head -1
}
xl=$(bestof "$DD" if="$ROOT/big" of=/dev/null bs=65536)
gn=$(bestof dd if="$ROOT/big" of=/dev/null bs=65536 status=none)
printf '  xlang dd: %ss\n' "$xl"
printf '  GNU dd:   %ss\n' "$gn"

rm -rf "$ROOT"
echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
