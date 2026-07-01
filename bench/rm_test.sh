#!/usr/bin/env bash
# Test rm.x vs GNU rm: single file, -r recursive, -f nonexistent, multi-file.
# Tree compare in parallel temp trees.
# Usage: rm_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/rm.x -o build/rm.c >/dev/null 2>&1; cc -O2 -o /tmp/xrm build/rm.c
R=/tmp/xrm

cmp_tree() {
    local label="$1"; shift
    local dx dg
    dx=$(mktemp -d); dg=$(mktemp -d)
    printf 'a' > "$dx/f1"; printf 'b' > "$dx/f2"
    printf 'a' > "$dg/f1"; printf 'b' > "$dg/f2"
    mkdir -p "$dx/tree/sub"; printf 'c' > "$dx/tree/x"; printf 'd' > "$dx/tree/sub/y"
    mkdir -p "$dg/tree/sub"; printf 'c' > "$dg/tree/x"; printf 'd' > "$dg/tree/sub/y"
    (cd "$dx" && "$R" "$@" 2>/dev/null)
    (cd "$dg" && rm "$@" 2>/dev/null)
    local tx tg
    tx=$(cd "$dx" && find . | sort)
    tg=$(cd "$dg" && find . | sort)
    if [ "$tx" = "$tg" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:$(echo "$tx"|tr '\n' ' ')"; echo "       g:$(echo "$tg"|tr '\n' ' ')"; FAIL=$((FAIL+1)); fi
    rm -rf "$dx" "$dg"
}

echo "== rm vs GNU (tree compare)"
cmp_tree "single file"  f1
cmp_tree "-r tree"      -r tree
cmp_tree "multi"        f1 f2
cmp_tree "-rf tree"     -rf tree

echo "== -f nonexistent (exit 0)"
d=$(mktemp -d)
if "$R" -f "$d/nonexistent" 2>/dev/null; then echo "  ok   rm -f missing -> exit 0"; PASS=$((PASS+1)); else echo "  FAIL rm -f missing"; FAIL=$((FAIL+1)); fi
rm -rf "$d"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
