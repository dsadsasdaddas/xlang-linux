#!/usr/bin/env bash
# Test strings.x vs GNU strings: extract printable strings from binary data.
# Usage: strings_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/strings.x -o build/strings.c >/dev/null 2>&1; cc -O2 -o /tmp/xstrings build/strings.c
S=/tmp/xstrings
ROOT="$(mktemp -d)"

# Binary data with NULs separating printable runs of varying length.
printf 'ab\x00hello\x00world\x00\x00ABCD\x00xy\x00longstring\x00' > "$ROOT/bin"

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$("$S" "$@" "$ROOT/bin" 2>/dev/null | sort)
    b=$(strings "$@" "$ROOT/bin" 2>/dev/null | sort)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== strings vs GNU"
cmp_gnu "default (>=4)"
cmp_gnu "-n 2"  -n 2

rm -rf "$ROOT"
echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
