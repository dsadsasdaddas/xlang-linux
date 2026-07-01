#!/usr/bin/env bash
# Test diff.x: identical files (exit 0, silent), different (exit 1), and the
# change-line ("<"/">") sets cross-checked vs GNU diff (sorted).
#
# Usage: diff_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/diff.x -o build/diff.c >/dev/null 2>&1; cc -O2 -o /tmp/xdiff build/diff.c
D=/tmp/xdiff
ROOT="$(mktemp -d)"
printf 'a\nb\nc\nd\ne\n'        > "$ROOT/f1"
printf 'a\nb\nX\nd\ne\n'        > "$ROOT/f2"   # c -> X
printf 'a\nb\nc\nd\ne\nextra\n' > "$ROOT/f3"   # + extra

echo "== identical files: exit 0, silent"
"$D" "$ROOT/f1" "$ROOT/f1" > /tmp/o 2>&1; rc=$?
if [ "$rc" = "0" ] && [ ! -s /tmp/o ]; then echo "  ok   identical -> exit 0, silent"; PASS=$((PASS+1)); else echo "  FAIL identical (rc=$rc)"; FAIL=$((FAIL+1)); fi

echo "== different files: exit 1"
"$D" "$ROOT/f1" "$ROOT/f2" > /dev/null 2>&1; rc=$?
if [ "$rc" = "1" ]; then echo "  ok   different -> exit 1"; PASS=$((PASS+1)); else echo "  FAIL different (rc=$rc)"; FAIL=$((FAIL+1)); fi

cmp_sets() {  # cmp_sets <label> <a> <b>
    local label="$1" fa="$2" fb="$3"
    local xa xb
    xa=$("$D" "$fa" "$fb" 2>/dev/null | grep -E '^[<>]' | sort)
    xb=$(diff "$fa" "$fb" 2>/dev/null | grep -E '^[<>]' | sort)
    if [ "$xa" = "$xb" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       xlang: $(echo "$xa"|tr '\n' ' ')"; echo "       gnu:   $(echo "$xb"|tr '\n' ' ')"; FAIL=$((FAIL+1)); fi
}

echo "== change-line sets vs GNU diff"
cmp_sets "modify (c->X)" "$ROOT/f1" "$ROOT/f2"
cmp_sets "insertion (+extra)" "$ROOT/f1" "$ROOT/f3"
cmp_sets "deletion (-extra)" "$ROOT/f3" "$ROOT/f1"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
