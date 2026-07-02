module main

// concat_builder — build a string with the sb_new/sb_push/sb_str builder (the
// O(n) baseline for concat_plus.x's O(n²) `+`-in-a-loop). Same workload:
// append "ab" N times, print final length.
//
// Usage: concat_builder <N>

fn main(): i32 {
    let mut n: i32 = 5000
    if argc() >= 2 {
        n = str_to_int(argv(1))
    }
    sb_new()
    let mut i: i32 = 0
    while i < n {
        sb_push("ab")
        i += 1
    }
    let s: String = sb_str()
    print_raw(int_to_str(str_len(s)))
    print_raw("\n")
    return 0
}
