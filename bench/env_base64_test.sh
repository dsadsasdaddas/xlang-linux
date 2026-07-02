#!/usr/bin/env bash
# Test env.x and base64.x: env vars + base64 encode/decode roundtrip.
# Usage: env_base64_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/env.x    -o build/env.c    >/dev/null 2>&1; cc -O2 -o /tmp/xenv    build/env.c
"$XLANGC" c coreutils/base64.x -o build/base64.c >/dev/null 2>&1; cc -O2 -o /tmp/xbase64 build/base64.c

echo "== env sets variable"
out=$(/tmp/xenv FOO=bar 2>/dev/null | grep '^FOO=')
if [ "$out" = "FOO=bar" ]; then echo "  ok   env FOO=bar"; PASS=$((PASS+1)); else echo "  FAIL env [$out]"; FAIL=$((FAIL+1)); fi

echo "== env -i empty"
out2=$(/tmp/xenv -i 2>/dev/null | wc -l)
if [ "$out2" = "0" ]; then echo "  ok   env -i is empty"; PASS=$((PASS+1)); else echo "  FAIL env -i ($out2 lines)"; FAIL=$((FAIL+1)); fi

echo "== base64 encode"
encoded=$(printf 'hello' | /tmp/xbase64 2>/dev/null)
expected="aGVsbG8="
if [ "$encoded" = "$expected" ]; then echo "  ok   base64 encode"; PASS=$((PASS+1)); else echo "  FAIL encode [$encoded]"; FAIL=$((FAIL+1)); fi

echo "== base64 decode roundtrip"
decoded=$(printf 'aGVsbG8=' | /tmp/xbase64 -d 2>/dev/null)
if [ "$decoded" = "hello" ]; then echo "  ok   base64 decode roundtrip"; PASS=$((PASS+1)); else echo "  FAIL decode [$decoded]"; FAIL=$((FAIL+1)); fi

echo "== base64 longer roundtrip"
input="The quick brown fox jumps over the lazy dog"
enc=$(printf '%s' "$input" | /tmp/xbase64 2>/dev/null)
dec=$(printf '%s' "$enc" | /tmp/xbase64 -d 2>/dev/null)
if [ "$dec" = "$input" ]; then echo "  ok   base64 long roundtrip"; PASS=$((PASS+1)); else echo "  FAIL long roundtrip [$dec]"; FAIL=$((FAIL+1)); fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
