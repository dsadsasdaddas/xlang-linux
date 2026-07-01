#!/usr/bin/env bash
# Test mv.x vs GNU mv: rename, move into dir, multi-file into dir. Tree compare.
# Usage: mv_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/mv.x -o build/mv.c >/dev/null 2>&1; cc -O2 -o /tmp/xmv build/mv.c
M=/tmp/xmv

# Run xlang mv and GNU mv on identical temp trees, compare resulting trees.
cmp_mv() {
    local label="$1"; shift
    local dx dg
    dx=$(mktemp -d); dg=$(mktemp -d)
    # Set up identical fixtures in both.
    printf 'a' > "$dx/f1"; printf 'b' > "$dx/f2"
    printf 'a' > "$dg/f1"; printf 'b' > "$dg/f2"
    mkdir -p "$dx/destdir"; mkdir -p "$dg/destdir"
    (cd "$dx" && "$M" "$@" 2>/dev/null)
    (cd "$dg" && mv "$@" 2>/dev/null)
    local tx tg
    tx=$(cd "$dx" && find . | sort)
    tg=$(cd "$dg" && find . | sort)
    if [ "$tx" = "$tg" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:$(echo "$tx"|tr '\n' ' ')"; echo "       g:$(echo "$tg"|tr '\n' ' ')"; FAIL=$((FAIL+1)); fi
    rm -rf "$dx" "$dg"
}

echo "== mv vs GNU (tree compare)"
cmp_mv "rename"          f1 f3
cmp_mv "into dir"        f1 destdir
cmp_mv "multi into dir"  f1 f2 destdir

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
