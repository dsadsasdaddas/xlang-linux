#!/usr/bin/env bash
# method_bench.sh — dogfood `impl` methods (merged to xlang main in #34) at
# scale: sum length_sq() over N points via a method call per element, and
# benchmark against the same workload in hand-written C (a free function — the
# exact thing xlang mangles a method into).
#
# Correctness gate: xlang and C produce the same total. Timing is informational
# — method dispatch should carry ~zero overhead vs a direct free-function call.
#
# Usage: method_bench.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
mkdir -p bin

"$XLANGC" c bench/method_bench.x -o build/method_bench.c >/dev/null 2>&1
cc -O2 -o bin/method_bench build/method_bench.c
cc -O2 -o bin/method_bench_ref bench/method_bench_ref.c

PASS=0; FAIL=0
echo "== correctness (method-call sum vs C free-function sum)"
for n in 1000 100000 2000000; do
    xl=$(./bin/method_bench "$n" 2>/dev/null)
    cf=$(./bin/method_bench_ref "$n" 2>/dev/null)
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
    printf "  %-32s %ss\n" "$label" "$t"
}
timeit "xlang method calls N=2M"  ./bin/method_bench     2000000
timeit "C free function   N=2M"   ./bin/method_bench_ref 2000000

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
