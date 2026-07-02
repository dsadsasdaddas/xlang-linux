module main

// factor <n>... — prime factorization (like GNU factor). Trial division.
// Multiple numbers supported (one per arg).

fn factor_one(n: i32): i32 {
    let mut remaining: i32 = n
    let mut d: i32 = 2
    print_raw(int_to_str(n))
    print_raw(":")
    while d * d <= remaining {
        while remaining % d == 0 {
            print_raw(" ")
            print_raw(int_to_str(d))
            remaining = remaining / d
        }
        d = d + 1
    }
    if remaining > 1 {
        print_raw(" ")
        print_raw(int_to_str(remaining))
    }
    print_raw("\n")
    return 0
}

fn main(): i32 {
    if argc() < 2 {
        let s: String = read_stdin()
        let n: i32 = str_len(s)
        let mut start: i32 = 0
        let mut k: i32 = 0
        while k <= n {
            let mut is_end: bool = (k == n)
            if k < n {
                let c: i32 = str_char_at(s, k)
                if c == 10 || c == 32 { is_end = true }
            }
            if is_end {
                if k > start {
                    factor_one(str_to_int(str_slice(s, start, k)))
                }
                start = k + 1
            }
            k = k + 1
        }
        return 0
    }
    let mut i: i32 = 1
    while i < argc() {
        factor_one(str_to_int(argv(i)))
        i = i + 1
    }
    return 0
}
