#!/usr/bin/env bash
# Test httpget.x against a local HTTP server (python3 http.server).
# Verifies body content, subpath, large multi-recv, and -o save.
#
# Usage: httpget_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
check() { if [ "$2" = "$3" ]; then echo "  ok   $1"; PASS=$((PASS+1)); else echo "  FAIL $1 (exp [$2] got [$3])"; FAIL=$((FAIL+1)); fi; }

mkdir -p build
"$XLANGC" c coreutils/httpget.x -o build/httpget.c >/dev/null 2>&1 || "$XLANGC" c coreutils/httpget.x >/dev/null 2>&1
cc -O2 -o /tmp/xlang_httpget build/httpget.c
H=/tmp/xlang_httpget

ROOT="$(mktemp -d)"
printf 'hello world\n' > "$ROOT/index.html"
seq 1 5000 > "$ROOT/big.txt"          # ~48 KB text (multi-recv)
head -c 8000 /dev/urandom > "$ROOT/bin.blob"   # 8 KB BINARY (has NUL bytes — the old failure case)
mkdir -p "$ROOT/sub"
printf 'sub page\n' > "$ROOT/sub/page.html"

python3 -m http.server 28700 --directory "$ROOT" >/dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null; rm -rf "$ROOT"' EXIT
sleep 0.6

echo "== GET /index.html"
check "index body" "hello world" "$($H http://127.0.0.1:28700/index.html | tr -d '\n')"

echo "== GET subpath"
check "sub body" "sub page" "$($H http://127.0.0.1:28700/sub/page.html | tr -d '\n')"

echo "== GET large file (multi-recv) — byte count must match source"
check "big size" "$(wc -c < "$ROOT/big.txt")" "$($H http://127.0.0.1:28700/big.txt | wc -c)"

echo "== -o save to file"
$H http://127.0.0.1:28700/index.html -o /tmp/hg_out
check "-o content" "$(cat "$ROOT/index.html")" "$(cat /tmp/hg_out)"

echo "== BINARY download via -o (8 KB with NUL bytes) byte-identical to source"
$H http://127.0.0.1:28700/bin.blob -o /tmp/hg_bin
if cmp -s /tmp/hg_bin "$ROOT/bin.blob"; then echo "  ok   bin.blob -o byte-identical (binary-safe)"; PASS=$((PASS+1)); else echo "  FAIL bin.blob -o differs"; FAIL=$((FAIL+1)); fi

echo "== BINARY download via stdout redirect byte-identical to source"
$H http://127.0.0.1:28700/bin.blob > /tmp/hg_bin2
if cmp -s /tmp/hg_bin2 "$ROOT/bin.blob"; then echo "  ok   bin.blob stdout byte-identical"; PASS=$((PASS+1)); else echo "  FAIL bin.blob stdout differs"; FAIL=$((FAIL+1)); fi

echo "== host without port (defaults to 80) — URL parses, connect fails gracefully"
out=$($H http://127.0.0.1/notreal 2>&1; echo "exit=$?")
echo "  (connect-fail handled: $out)" | head -c 80; echo

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
