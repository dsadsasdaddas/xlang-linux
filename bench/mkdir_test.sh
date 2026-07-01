#!/usr/bin/env bash
# Test mkdir.x vs GNU mkdir: run the same args in two parallel temp trees and
# compare the resulting directory trees (find | sort).
# Usage: mkdir_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/mkdir.x -o build/mkdir.c >/dev/null 2>&1; cc -O2 -o /tmp/xmkdir build/mkdir.c
M=/tmp/xmkdir

cmp_tree() {
    local label="$1"; shift
    local dx dg
    dx=$(mktemp -d); dg=$(mktemp -d)
    (cd "$dx" && "$M" "$@" 2>/dev/null)
    (cd "$dg" && mkdir "$@" 2>/dev/null)
    local tx tg
    tx=$(cd "$dx" && find . | sort)
    tg=$(cd "$dg" && find . | sort)
    if [ "$tx" = "$tg" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:$(echo "$tx"|tr '\n' ' ')"; echo "       g:$(echo "$tg"|tr '\n' ' ')"; FAIL=$((FAIL+1)); fi
    rm -rf "$dx" "$dg"
}

echo "== mkdir vs GNU (tree compare)"
cmp_tree "simple"          d
cmp_tree "multi"           d e f
cmp_tree "-p nested"       -p a/b/c
cmp_tree "-p existing"     -p g
cmp_tree "-p multi-nested" -p x/y z/w

echo "== -p on an existing dir is idempotent (exit 0)"
d=$(mktemp -d)
"$M" -p "$d/sub" >/dev/null 2>&1
if "$M" -p "$d/sub" >/dev/null 2>&1; then echo "  ok   mkdir -p existing -> exit 0"; PASS=$((PASS+1)); else echo "  FAIL mkdir -p existing"; FAIL=$((FAIL+1)); fi
rm -rf "$d"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
