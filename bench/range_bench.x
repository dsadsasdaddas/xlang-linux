module main

// range_bench — Sieve of Eratosthenes that exercises the new `for i in a..b`
// numeric range loops at scale, and serves as a codegen-perf benchmark:
// xlang's output should match hand-written C (range_bench_ref.c) since range
// loops lower to the same `for (i = a; i < b; i++)`.
//
// Usage: range_bench [N]   (default N = 1000000)
// Prints the count of primes < N. Known values: <10 → 4, <100 → 25,
// <1000 → 168, <10000 → 1229, <1000000 → 78498.

fn main(): i32 {
    let mut n: i32 = 1000000
    if argc() >= 2 {
        n = str_to_int(argv(1))
    }
    if n < 2 {
        print_raw("0\n")
        return 0
    }

    // Sieve table: comp[p] == 1 means p is composite. Built with a range loop.
    let comp: Vec<i32> = vec_new()
    for k in 0..n {
        comp.push(0)
    }

    // Outer walk + inner marking. The step-1 outer loop is a range-for; the
    // inner marking loop steps by p, so it stays a while (range-for is step-1).
    // `p <= n / p` is the overflow-safe form of `p*p <= n`: for primes near n,
    // p*p would overflow i32 to a negative value and the inner loop would run
    // with a negative index (out-of-bounds write). Skip marking once p*p > n.
    let mut count: i32 = 0
    for p in 2..n {
        if comp[p] == 0 {
            count += 1
            if p <= n / p {
                let mut m: i32 = p * p
                while m < n {
                    comp[m] = 1
                    m += p
                }
            }
        }
    }

    print_raw(int_to_str(count))
    print_raw("\n")
    return 0
}
