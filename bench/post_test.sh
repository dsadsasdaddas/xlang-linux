#!/usr/bin/env bash
# End-to-end BINARY POST test: httpget -X POST -d @binfile uploads a binary body,
# captured by `nc -l` on the receiving end — both directly and through the proxy.
# Verifies the binary body arrives byte-identical (the C-string model would
# truncate it at the first NUL without the binary-safe send_rbuf/recv_n path).
#
# Usage: post_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/httpget.x -o build/httpget.c >/dev/null 2>&1 || "$XLANGC" c coreutils/httpget.x >/dev/null 2>&1
cc -O2 -o /tmp/xlang_httpget build/httpget.c
"$XLANGC" c coreutils/nc.x -o build/nc.c >/dev/null 2>&1; cc -O2 -o /tmp/xlang_nc2 build/nc.c
"$XLANGC" c ../xlang-nginx/servers/server_proxy.x -o build/server_proxy.c >/dev/null 2>&1; cc -O2 -o /tmp/xlang_proxyp build/server_proxy.c
H=/tmp/xlang_httpget; NC=/tmp/xlang_nc2

ROOT="$(mktemp -d)"
head -c 12000 /dev/urandom > "$ROOT/bin.blob"     # 12 KB binary (has NUL bytes)
BINSZ=$(wc -c < "$ROOT/bin.blob")

# body_ok <captured>: do the last BINSZ bytes equal bin.blob?
body_ok() { tail -c "$BINSZ" "$1" | cmp -s - "$ROOT/bin.blob"; }

# A canned 200 response fed to `nc -l`'s stdin so it acts as a real server
# (sends a reply) — without it the proxy deadlocks waiting for the client's next
# request while httpget waits for a response.
RESP="HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"

echo "== POST direct: httpget -> nc -l (binary body)"
printf "$RESP" | "$NC" -l 29200 > /tmp/post_direct 2>/dev/null & LP=$!
sleep 0.4
timeout 6 "$H" -X POST -d @"$ROOT/bin.blob" http://127.0.0.1:29200/upload >/dev/null 2>&1
sleep 0.3; kill "$LP" 2>/dev/null
if body_ok /tmp/post_direct; then echo "  ok   direct POST binary body intact"; PASS=$((PASS+1)); else echo "  FAIL direct POST body"; FAIL=$((FAIL+1)); fi

echo "== POST through proxy: httpget -> proxy -> nc -l (binary body)"
printf "$RESP" | "$NC" -l 29201 > /tmp/post_proxied 2>/dev/null & BP=$!
/tmp/xlang_proxyp 29202 4 127.0.0.1:29201 >/dev/null 2>&1 &
sleep 0.5
timeout 6 "$H" -X POST -d @"$ROOT/bin.blob" http://127.0.0.1:29202/upload >/dev/null 2>&1
sleep 0.4; kill "$BP" 2>/dev/null; pkill -f xlang_proxyp 2>/dev/null
if body_ok /tmp/post_proxied; then echo "  ok   proxied POST binary body intact"; PASS=$((PASS+1)); else echo "  FAIL proxied POST body"; FAIL=$((FAIL+1)); fi

rm -rf "$ROOT"
echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
