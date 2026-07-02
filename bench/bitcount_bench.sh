#!/usr/bin/env bash
# bitcount_bench.sh — exercise based-integer literals + bitwise ops + inclusive
# range loops via a popcount kernel, and benchmark xlang codegen vs hand-written
# C. Mirrors range_bench.sh: correctness gates the exit code (xlang and C must
# agree — both run the identical algorithm, so agreement validates the codegen),
# timing is informational.
#
# Usage: bitcount_bench.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
mkdir -p build bin

"$XLANGC" c bench/bitcount_bench.x -o build/bitcount_bench.c >/dev/null 2>&1
cc -O2 -o bin/bitcount_bench build/bitcount_bench.c
cc -O2 -o bin/bitcount_bench_ref bench/bitcount_bench_ref.c

PASS=0; FAIL=0
echo "== correctness (xlang vs hand-written C, identical algorithm)"
for n in 10 100 1000 1000000; do
    xl=$(./bin/bitcount_bench "$n" 2>/dev/null)
    cf=$(./bin/bitcount_bench_ref "$n" 2>/dev/null)
    if [ "$xl" = "$cf" ] && [ -n "$xl" ]; then
        echo "  ok   N=$n → $xl"; PASS=$((PASS+1))
    else
        echo "  FAIL N=$n → xlang $xl, C $cf"; FAIL=$((FAIL+1))
    fi
done

echo "== perf vs hand-written C (informational)"
timeit() {  # timeit <label> <exe> <N>
    local label="$1" exe="$2" n="$3" t
    t=$(/usr/bin/time -f "%e" "$exe" "$n" 2>&1 >/dev/null | tail -1)
    printf "  %-26s %ss  (N=%s)\n" "$label" "$t" "$n"
}
BIG=10000000
timeit "xlang popcount"      ./bin/bitcount_bench "$BIG"
timeit "hand-written C"      ./bin/bitcount_bench_ref "$BIG"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
