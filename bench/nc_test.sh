#!/usr/bin/env bash
# Test nc.x: connect mode (talk to an HTTP server) + binary round-trip through
# two nc's (connect -> listen). Uses python http.server (always available).
#
# Usage: nc_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/nc.x -o build/nc.c >/dev/null 2>&1 || "$XLANGC" c coreutils/nc.x >/dev/null 2>&1
cc -O2 -o /tmp/xlang_nc build/nc.c
NC=/tmp/xlang_nc

ROOT="$(mktemp -d)"
printf 'hello-body\n' > "$ROOT/index.html"
head -c 10000 /dev/urandom > "$ROOT/bin.blob"     # 10 KB binary (has NUL bytes)

echo "== connect mode: send a raw HTTP request via nc -> python http.server"
python3 -m http.server 28801 --directory "$ROOT" >/dev/null 2>&1 &
SRV=$!
sleep 0.5
resp=$(printf 'GET /index.html HTTP/1.0\r\nHost: x\r\n\r\n' | timeout 5 "$NC" 127.0.0.1 28801)
kill "$SRV" 2>/dev/null
echo "$resp" | grep -q '200 OK'   && { echo "  ok   got 200 OK"; PASS=$((PASS+1)); } || { echo "  FAIL no 200 OK"; FAIL=$((FAIL+1)); }
echo "$resp" | grep -q 'hello-body' && { echo "  ok   got body";   PASS=$((PASS+1)); } || { echo "  FAIL no body";   FAIL=$((FAIL+1)); }

echo "== binary round-trip: cat bin | nc(connect) -> nc(-l) > out, byte-identical"
"$NC" -l 28802 < /dev/null > /tmp/nc_recv 2>/dev/null &
LP=$!
sleep 0.4
cat "$ROOT/bin.blob" | timeout 5 "$NC" 127.0.0.1 28802
sleep 0.4
kill "$LP" 2>/dev/null
if cmp -s /tmp/nc_recv "$ROOT/bin.blob"; then
    echo "  ok   binary round-trip byte-identical"; PASS=$((PASS+1))
else
    echo "  FAIL binary round-trip differs ($(wc -c < /tmp/nc_recv 2>/dev/null) of $(wc -c < "$ROOT/bin.blob") bytes)"; FAIL=$((FAIL+1))
fi

rm -rf "$ROOT"
echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
