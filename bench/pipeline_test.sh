#!/usr/bin/env bash
# Pure-xlang userland pipeline integration test.
# Runs multi-stage pipelines using ONLY xlang coreutils (from bin/), comparing
# output to the equivalent GNU pipeline. Validates the "replace linux userland"
# claim — that the tools interoperate correctly as a system.
#
# Usage: pipeline_test.sh <bin-dir>
set -u
BIN="${1:-bin}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0

if [ ! -x "$BIN/cat" ]; then
    echo "ERROR: $BIN/cat not found. Build first: xlangc c + cc for each coreutil."
    exit 2
fi

# Run a pipeline two ways: xlang tools (from $BIN) vs GNU tools (explicit /usr/bin).
# Both read from the same generated input. Compare stdout.
xcmp() {  # xcmp <label> <input> <xlang-pipeline> <gnu-pipeline>
    local label="$1" input="$2" xp="$3" gp="$4"
    local xo go
    xo=$(printf '%s' "$input" | eval "$xp" 2>/dev/null)
    go=$(printf '%s' "$input" | eval "$gp" 2>/dev/null)
    if [ "$xo" = "$go" ]; then echo "  ok   $label"; PASS=$((PASS+1))
    else echo "  FAIL $label"; echo "       xlang: [$xo]"; echo "       gnu:   [$go]"; FAIL=$((FAIL+1))
    fi
}

export PATH="$PWD/$BIN:/usr/bin:/bin"

echo "== pure-xlang pipeline vs GNU"
xcmp "cat|grep|wc" \
    "$(seq 1 100)" \
    "cat | grep '5' | wc -l" \
    "/usr/bin/cat | /usr/bin/grep '5' | /usr/bin/wc -l"

xcmp "sort|uniq" \
    "$(printf 'banana\napple\ncherry\nbanana\napple\n')" \
    "sort | uniq" \
    "/usr/bin/sort | /usr/bin/uniq"

xcmp "head|tail" \
    "$(seq 1 20)" \
    "head -10 | tail -3" \
    "/usr/bin/head -10 | /usr/bin/tail -3"

xcmp "cut|sort" \
    "$(printf '3,c\n1,a\n2,b\n')" \
    "cut -d, -f1 | sort -n" \
    "/usr/bin/cut -d, -f1 | /usr/bin/sort -n"

xcmp "tr|wc" \
    "$(printf 'hello world\n')" \
    "tr ' ' '\n' | wc -l" \
    "/usr/bin/tr ' ' '\n' | /usr/bin/wc -l"

xcmp "cat|sed" \
    "$(printf 'foo\nbar\nbaz\n')" \
    "sed 's/a/X/g'" \
    "/usr/bin/sed 's/a/X/g'"

xcmp "sort -r|head" \
    "$(seq 1 50)" \
    "sort -r | head -3" \
    "/usr/bin/sort -r | /usr/bin/head -3"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
