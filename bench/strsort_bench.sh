#!/usr/bin/env bash
# strsort_bench.sh — dogfood the new string comparison operators (`<`, `==`,
# lowered to strcmp, merged to xlang main in #33) via a selection sort, and
# benchmark against C qsort(strcmp). Selection sort is O(n²) in comparisons,
# so this stresses the strcmp codegen directly.
#
# Correctness gate: xlang and C must produce the same sorted first..last.
# Timing is informational: the C reference uses the SAME O(n²) selection sort
# (not qsort), so the gap is pure codegen — the strcmp lowering should carry
# ~zero overhead vs hand-written C.
#
# Usage: strsort_bench.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
mkdir -p bin

"$XLANGC" c bench/strsort_bench.x -o build/strsort_bench.c >/dev/null 2>&1
cc -O2 -o bin/strsort_bench build/strsort_bench.c
cc -O2 -o bin/strsort_bench_ref bench/strsort_bench_ref.c

PASS=0; FAIL=0
echo "== correctness (xlang selection-sort vs C qsort, same strings)"
for n in 100 1000 4000; do
    xl=$(./bin/strsort_bench "$n" 2>/dev/null)
    cf=$(./bin/strsort_bench_ref "$n" 2>/dev/null)
    if [ "$xl" = "$cf" ] && [ -n "$xl" ]; then
        echo "  ok   N=$n → $xl"; PASS=$((PASS+1))
    else
        echo "  FAIL N=$n → xlang [$xl], C [$cf]"; FAIL=$((FAIL+1))
    fi
done

echo "== perf (informational — same O(n²) selection sort, gap is pure codegen)"
timeit() {  # timeit <label> <exe> <N>
    local label="$1" exe="$2" n="$3" t
    t=$(/usr/bin/time -f "%e" "$exe" "$n" 2>&1 >/dev/null | tail -1)
    printf "  %-34s %ss\n" "$label" "$t"
}
timeit "xlang selection-sort N=4000" ./bin/strsort_bench 4000
timeit "C selection-sort    N=4000" ./bin/strsort_bench_ref 4000

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
