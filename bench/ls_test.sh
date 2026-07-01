#!/usr/bin/env bash
# Test the upgraded ls.x: name lists (-a, subdir) cross-checked vs GNU ls; -l
# structural (perm prefix); -R structural (headers + recursion).
#
# Usage: ls_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/ls.x -o build/ls.c >/dev/null 2>&1; cc -O2 -o /tmp/xls build/ls.c
L=/tmp/xls
ROOT="$(mktemp -d)"
printf 'x' > "$ROOT/alpha.txt"
printf 'x' > "$ROOT/beta.dat"
mkdir "$ROOT/gamma"
printf 'x' > "$ROOT/gamma/inner.txt"
printf 'x' > "$ROOT/.hidden"

cmp_gnu() {  # cmp_gnu <label> <args...>
    local label="$1"; shift
    local a b
    a=$(cd "$ROOT" && "$L" "$@" 2>/dev/null | sort)
    b=$(cd "$ROOT" && ls "$@" 2>/dev/null | sort)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       xlang: $(echo "$a"|tr '\n' ' ')"; echo "       gnu:   $(echo "$b"|tr '\n' ' ')"; FAIL=$((FAIL+1)); fi
}

echo "== name lists vs GNU ls (sorted)"
cmp_gnu "ls ."       .
cmp_gnu "ls -a ."    -a .
cmp_gnu "ls gamma"   gamma

echo "== ls -l structural (perm-prefixed entry lines)"
out=$(cd "$ROOT" && "$L" -l . 2>/dev/null)
nperm=$(echo "$out" | grep -cE '^[dl-][rwx-]{9} ')
if [ "$nperm" -ge 3 ]; then echo "  ok   ls -l has $nperm perm-prefixed lines"; PASS=$((PASS+1)); else echo "  FAIL ls -l (only $nperm perm lines)"; FAIL=$((FAIL+1)); fi

echo "== ls -R structural (header + recursion)"
out=$(cd "$ROOT" && "$L" -R . 2>/dev/null)
if echo "$out" | grep -q 'gamma:$' && echo "$out" | grep -q 'inner.txt'; then
    echo "  ok   ls -R recurses with dir header"; PASS=$((PASS+1))
else
    echo "  FAIL ls -R"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
