#!/usr/bin/env bash
# Test factor.x, shuf.x, date.x — structural verification.
# Usage: misc_tools_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/factor.x -o build/factor.c >/dev/null 2>&1; cc -O2 -o /tmp/xfactor build/factor.c
"$XLANGC" c coreutils/shuf.x   -o build/shuf.c   >/dev/null 2>&1; cc -O2 -o /tmp/xshuf   build/shuf.c
"$XLANGC" c coreutils/date.x   -o build/date.c   >/dev/null 2>&1; cc -O2 -o /tmp/xdate   build/date.c

echo "== factor"
out=$(/tmp/xfactor 60 2>/dev/null)
if [ "$out" = "60: 2 2 3 5" ]; then echo "  ok   factor 60"; PASS=$((PASS+1)); else echo "  FAIL factor 60 [$out]"; FAIL=$((FAIL+1)); fi

out2=$(/tmp/xfactor 13 2>/dev/null)
if [ "$out2" = "13: 13" ]; then echo "  ok   factor 13 (prime)"; PASS=$((PASS+1)); else echo "  FAIL factor 13 [$out2]"; FAIL=$((FAIL+1)); fi

out3=$(/tmp/xfactor 100 2>/dev/null)
if [ "$out3" = "100: 2 2 5 5" ]; then echo "  ok   factor 100"; PASS=$((PASS+1)); else echo "  FAIL factor 100 [$out3]"; FAIL=$((FAIL+1)); fi

out4=$(/tmp/xfactor 12 18 2>/dev/null | tr '\n' '~')
if [ "$out4" = "12: 2 2 3~18: 2 3 3~" ]; then echo "  ok   factor multi"; PASS=$((PASS+1)); else echo "  FAIL multi [$out4]"; FAIL=$((FAIL+1)); fi

echo "== shuf"
out5=$(printf 'a\nb\nc\nd\n' | /tmp/xshuf 2>/dev/null | sort | tr '\n' '~')
if [ "$out5" = "a~b~c~d~" ]; then echo "  ok   shuf preserves all lines"; PASS=$((PASS+1)); else echo "  FAIL shuf [$out5]"; FAIL=$((FAIL+1)); fi

echo "== date"
out6=$(/tmp/xdate 2>/dev/null)
if echo "$out6" | grep -qE '^[A-Z][a-z]{2} [A-Z][a-z]{2} +[0-9]'; then echo "  ok   date format"; PASS=$((PASS+1)); else echo "  FAIL date [$out6]"; FAIL=$((FAIL+1)); fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
