module main

// concat_plus — build a string by repeated `s = s + chunk` (the new string `+`
// operator). Demonstrates its performance contract: each `+` allocates a fresh
// buffer and copies both operands, so accumulating in a loop is O(n²) total
// copy. Use `+` for one-off expressions (`name + ": " + int_to_str(n)`); use
// the sb_new/sb_push/sb_str builder for loops.
//
// Usage: concat_plus <N>   — appends "ab" N times via `+`, prints final length.

fn main(): i32 {
    let mut n: i32 = 5000
    if argc() >= 2 {
        n = str_to_int(argv(1))
    }
    let mut s: String = ""
    let mut i: i32 = 0
    // O(n²): each `+` reallocates and copies the growing accumulator.
    while i < n {
        s = s + "ab"
        i += 1
    }
    print_raw(int_to_str(str_len(s)))
    print_raw("\n")
    return 0
}
