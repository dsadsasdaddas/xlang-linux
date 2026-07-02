#!/usr/bin/env bash
# range_bench.sh — exercise the new `for i in a..b` numeric range loops via a
# Sieve of Eratosthenes, and benchmark xlang's codegen against hand-written C.
#
# Two parts:
#   1. Correctness (gates exit code): range_bench.x must produce the known
#      prime counts. This is a cross-repo integration test for the range-for
#      feature (xlang-linux CI compiles against xlang main).
#   2. Perf (informational): time range_bench.x vs range_bench_ref.c at large N.
#      range-for lowers to the same C `for` the hand-written version uses; the
#      residual gap is the Vec<i32> (4 B/entry, realloc'd) vs char[] (1 B/entry)
#      data-structure choice, not loop codegen.
#
# Usage: range_bench.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
mkdir -p build bin

# Compile the xlang sieve (.x -> C -> exe).
"$XLANGC" c bench/range_bench.x -o build/range_bench.c >/dev/null 2>&1
cc -O2 -o bin/range_bench build/range_bench.c
# Compile the hand-written C reference.
cc -O2 -o bin/range_bench_ref bench/range_bench_ref.c

PASS=0; FAIL=0
check() {  # check <N> <expected>
    local n="$1" exp="$2"
    local got
    got=$(./bin/range_bench "$n" 2>/dev/null)
    if [ "$got" = "$exp" ]; then
        echo "  ok   range_bench $n → $got"; PASS=$((PASS+1))
    else
        echo "  FAIL range_bench $n → got $got, want $exp"; FAIL=$((FAIL+1))
    fi
}

echo "== correctness (prime counts)"
check 10 4
check 100 25
check 1000 168
check 10000 1229
check 1000000 78498

echo "== perf vs hand-written C (informational)"
timeit() {  # timeit <label> <exe> <N>
    local label="$1" exe="$2" n="$3"
    # /usr/bin/time writes "%e" (wall seconds) to stderr; route the program's
    # stdout to /dev/null and capture only the timing line.
    local t
    t=$(/usr/bin/time -f "%e" "$exe" "$n" 2>&1 >/dev/null | tail -1)
    printf "  %-26s %ss  (N=%s)\n" "$label" "$t" "$n"
}
BIG=10000000
# Verify the two agree at the benchmark size (cross-check correctness).
xl=$(./bin/range_bench "$BIG" 2>/dev/null)
cf=$(./bin/range_bench_ref "$BIG" 2>/dev/null)
if [ "$xl" != "$cf" ]; then
    echo "  WARN xlang ($xl) and C ref ($cf) disagree at N=$BIG"; FAIL=$((FAIL+1))
fi
timeit "xlang range-for sieve" ./bin/range_bench "$BIG"
timeit "hand-written C sieve"  ./bin/range_bench_ref "$BIG"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
