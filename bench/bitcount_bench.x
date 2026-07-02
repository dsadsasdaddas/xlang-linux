module main

// bitcount_bench — population count (popcount) over N pseudo-random i32.
// Dogfoods the based-integer-literals + bitwise-ops + range-loop features at
// scale, and benchmarks xlang codegen against hand-written C.
//
// popcount counts the set bits in a 32-bit word with a fixed 32-iteration
// loop (so it works regardless of the sign bit under arithmetic >>). The
// benchmark body mixes the loop index and sums popcounts — a real workload
// shape (compression, bioinformatics, databases all count bits).
//
// Usage: bitcount_bench [N]   (default N = 10000000)

fn popcount(x: i32): i32 {
    let mut c: i32 = 0
    let mut v: i32 = x
    // Inclusive range 0..=31 → 32 iterations, one per bit.
    for b in 0..=31 {
        if (v & 1) != 0 {
            c += 1
        }
        v = v >> 1
    }
    return c
}

fn main(): i32 {
    let mut n: i32 = 10000000
    if argc() >= 2 {
        n = str_to_int(argv(1))
    }
    let mut total: i32 = 0
    for i in 0..n {
        // Deterministic, overflow-free bit mixing (i is non-negative): shifts
        // and XOR never overflow i32, so no signed-overflow UB.
        let v: i32 = i ^ (i >> 3)
        total += popcount(v)
    }
    print_raw(int_to_str(total))
    print_raw("\n")
    return 0
}
