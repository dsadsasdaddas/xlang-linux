#!/usr/bin/env bash
# Test calc.x: arithmetic with precedence, parentheses, floats, unary minus.
# Usage: calc_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/calc.x -o build/calc.c >/dev/null 2>&1; cc -O2 -o /tmp/xcalc build/calc.c
C=/tmp/xcalc

check() {
    local label="$1" expected="$2" expr="$3"
    local actual
    actual=$("$C" "$expr" 2>/dev/null)
    if [ "$actual" = "$expected" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label (exp [$expected] got [$actual])"; FAIL=$((FAIL+1)); fi
}

echo "== calc expressions"
check "add"           "5"       "2 + 3"
check "precedence"    "7"       "1 + 2 * 3"
check "parens"        "9"       "(1 + 2) * 3"
check "float"         "6.28"    "3.14 * 2"
check "unary minus"   "-2"      "-5 + 3"
check "division"      "14.2857" "100 / 7"
check "nested parens" "4"       "((1 + 1) * (3 - 1))"
check "complex"       "23"      "2 * 3 + 4 * 5 - 3"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
