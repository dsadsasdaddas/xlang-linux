#!/usr/bin/env bash
# Test timeout.x: kills an over-running command, lets a fast one finish, forwards
# output.
#
# Usage: timeout_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/timeout.x -o build/timeout.c >/dev/null 2>&1 || "$XLANGC" c coreutils/timeout.x >/dev/null 2>&1
cc -O2 -o /tmp/xlang_timeout build/timeout.c
T=/tmp/xlang_timeout

echo "== timeout 2 sleep 10 — should be killed after ~2s (non-zero exit)"
t0=$(date +%s)
"$T" 2 sleep 10
rc=$?
t1=$(date +%s)
elapsed=$((t1 - t0))
if [ "$rc" -ne 0 ] && [ "$elapsed" -ge 1 ] && [ "$elapsed" -le 5 ]; then
    echo "  ok   killed (exit=$rc, ~${elapsed}s)"; PASS=$((PASS+1))
else
    echo "  FAIL exit=$rc elapsed=${elapsed}s"; FAIL=$((FAIL+1))
fi

echo "== timeout 5 true — finishes in time (exit 0)"
"$T" 5 true
rc=$?
if [ "$rc" -eq 0 ]; then echo "  ok   exit 0"; PASS=$((PASS+1)); else echo "  FAIL exit=$rc"; FAIL=$((FAIL+1)); fi

echo "== timeout 5 echo hello — output forwarded, exit 0"
out=$("$T" 5 /bin/echo hello)
rc=$?
if [ "$rc" -eq 0 ] && [ "$out" = "hello" ]; then
    echo "  ok   output '$out', exit 0"; PASS=$((PASS+1))
else
    echo "  FAIL out='$out' exit=$rc"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
