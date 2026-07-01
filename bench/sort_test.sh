#!/usr/bin/env bash
# Test sort.x vs GNU sort: default, -n, -r, -u, -ru, -nu, -nru.
# Usage: sort_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/sort.x -o build/sort.c >/dev/null 2>&1; cc -O2 -o /tmp/xsort build/sort.c
S=/tmp/xsort
INPUT=$'3\n1\n2\n3\n1\n10\n2\n'

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$INPUT" | "$S" "$@" 2>/dev/null)
    b=$(printf '%s' "$INPUT" | sort "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== sort vs GNU"
cmp_gnu "default"
cmp_gnu "-n"       -n
cmp_gnu "-r"       -r
cmp_gnu "-u"       -u
cmp_gnu "-nr"      -nr
cmp_gnu "-nu"      -nu
cmp_gnu "-nru"     -nru

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
