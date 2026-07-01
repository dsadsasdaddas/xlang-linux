#!/usr/bin/env bash
# Test xwrk.x against xlang server_http (keepalive), sanity-check the req/s it
# reports. (Detailed comparison vs python bench_py.py is done separately.)
#
# Usage: xwrk_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

mkdir -p build
"$XLANGC" c coreutils/xwrk.x -o build/xwrk.c >/dev/null 2>&1 || "$XLANGC" c coreutils/xwrk.x >/dev/null 2>&1
cc -O2 -o /tmp/xlang_xwrk build/xwrk.c

# Backend: xlang server_http from the sibling xlang-nginx repo (keepalive).
NGINX_REPO=../xlang-nginx
if [ -f "$NGINX_REPO/servers/server_http.x" ]; then
    "$XLANGC" c "$NGINX_REPO/servers/server_http.x" -o build/server_http.c >/dev/null 2>&1
    cc -O2 -o /tmp/xwrk_srv build/server_http.c
    ROOT="$(mktemp -d)"; printf 'hello\n' > "$ROOT/index.html"
    /tmp/xwrk_srv "$ROOT" 28901 >/dev/null 2>&1 &
else
    ROOT="$(mktemp -d)"; printf 'hello\n' > "$ROOT/index.html"
    python3 -m http.server 28901 --directory "$ROOT" >/dev/null 2>&1 &
fi
SP=$!
trap 'kill $SP 2>/dev/null; rm -rf "$ROOT" /tmp/xwrk_*' EXIT
sleep 0.5

echo "== xwrk 127.0.0.1:28901 /index.html 3s @ 16 conns"
out=$(/tmp/xlang_xwrk 127.0.0.1 28901 /index.html 3 16)
echo "$out"
rps=$(echo "$out" | sed -n 's/.*= \([0-9][0-9]*\) req\/s.*/\1/p')
echo "parsed req/s = ${rps:-0}"
if [ "${rps:-0}" -gt 100 ]; then
    echo "ok: xwrk reports a sane req/s (>100)"; PASS=1
else
    echo "FAIL: xwrk req/s too low (got ${rps:-0})"; PASS=0
fi
[ "$PASS" = 1 ]
