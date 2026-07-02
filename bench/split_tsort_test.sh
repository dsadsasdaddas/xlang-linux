#!/usr/bin/env bash
# Test split.x and tsort.x — these have non-standard interfaces (split writes
# files, tsort does topological sort), so tested structurally rather than
# vs GNU directly.
# Usage: split_tsort_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/split.x  -o build/split.c  >/dev/null 2>&1; cc -O2 -o /tmp/xsplit  build/split.c
"$XLANGC" c coreutils/tsort.x  -o build/tsort.c  >/dev/null 2>&1; cc -O2 -o /tmp/xtsort  build/tsort.c

echo "== split"
ROOT="$(mktemp -d)"
seq 1 10 > "$ROOT/input"
cd "$ROOT"
/tmp/xsplit input 3 >/dev/null 2>&1
nfiles=$(ls xsplit_* 2>/dev/null | wc -l)
lines_0=$(cat xsplit_0 2>/dev/null | wc -l)
lines_1=$(cat xsplit_1 2>/dev/null | wc -l)
total=$(cat xsplit_* | wc -l)
if [ "$nfiles" -eq 4 ] && [ "$lines_0" -eq 3 ] && [ "$lines_1" -eq 3 ] && [ "$total" -eq 10 ]; then
    echo "  ok   split 10 lines / 3 = 4 files (3+3+3+1)"; PASS=$((PASS+1))
else
    echo "  FAIL split (files=$nfiles l0=$lines_0 l1=$lines_1 total=$total)"; FAIL=$((FAIL+1))
fi
cd - >/dev/null
rm -rf "$ROOT"

echo "== tsort"
INPUT=$'a b\nb c\nc d\n'
result=$(printf '%s' "$INPUT" | /tmp/xtsort 2>/dev/null)
expected=$'a\nb\nc\nd'
if [ "$result" = "$expected" ]; then
    echo "  ok   tsort linear chain a→b→c→d"; PASS=$((PASS+1))
else
    echo "  FAIL tsort (got [$result])"; FAIL=$((FAIL+1))
fi

INPUT2=$'shirt belt\nbelt pants\npants shoes\n'
result2=$(printf '%s' "$INPUT2" | /tmp/xtsort 2>/dev/null)
if echo "$result2" | head -1 | grep -q 'shirt' && echo "$result2" | tail -1 | grep -q 'shoes'; then
    echo "  ok   tsort dependencies (shirt before shoes)"; PASS=$((PASS+1))
else
    echo "  FAIL tsort deps (got [$result2])"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
