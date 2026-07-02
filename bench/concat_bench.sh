#!/usr/bin/env bash
# concat_bench.sh — documents the performance contract of the new string `+`
# operator (merged to xlang main in #32). `+` allocates a fresh buffer per
# concatenation, so accumulating in a loop (`s = s + chunk`) is O(n²) total
# copy, while the sb_push builder is amortized O(n).
#
# This is intentional and matches Rust/Java/etc.: use `+` for one-off
# expressions (`name + ": " + int_to_str(n)`), the builder for loops. The
# bench cross-checks both produce the same length (correctness gate) and times
# them at increasing N to show the scaling gap.
#
# Usage: concat_bench.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
mkdir -p bin

"$XLANGC" c bench/concat_plus.x   -o build/concat_plus.c   >/dev/null 2>&1
cc -O2 -o bin/concat_plus   build/concat_plus.c
"$XLANGC" c bench/concat_builder.x -o build/concat_builder.c >/dev/null 2>&1
cc -O2 -o bin/concat_builder build/concat_builder.c

PASS=0; FAIL=0
echo "== correctness (same length from both)"
for n in 100 1000 5000; do
    p=$(./bin/concat_plus "$n" 2>/dev/null)
    b=$(./bin/concat_builder "$n" 2>/dev/null)
    if [ "$p" = "$b" ] && [ -n "$p" ]; then
        echo "  ok   N=$n → len $p"; PASS=$((PASS+1))
    else
        echo "  FAIL N=$n → plus $p, builder $b"; FAIL=$((FAIL+1))
    fi
done

echo "== scaling: `+`-in-loop (O(n²)) vs sb_push builder (O(n))"
timeit() {  # timeit <label> <exe> <N>
    local label="$1" exe="$2" n="$3" t
    t=$(/usr/bin/time -f "%e" "$exe" "$n" 2>&1 >/dev/null | tail -1)
    printf "  %-30s %ss\n" "$label" "$t"
}
timeit "plus   N=5000"  ./bin/concat_plus   5000
timeit "builder N=5000" ./bin/concat_builder 5000
timeit "plus   N=20000" ./bin/concat_plus   20000
timeit "builder N=20000" ./bin/concat_builder 20000

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
