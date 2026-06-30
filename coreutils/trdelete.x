module main

// trdelete <chars> — remove all chars in the set from stdin (like `tr -d`).
// Uses sb_push_char for zero-allocation O(n) output.
fn main(): i32 {
    if argc() < 2 {
        print_str("usage: trdelete <chars>")
        return 1
    }
    let chars: String = argv(1)
    let s: String = read_stdin()
    let n: i32 = str_len(s)
    let cn: i32 = str_len(chars)
    let mut i: i32 = 0
    sb_new()
    while i < n {
        let c: i32 = str_char_at(s, i)
        let mut in_set: bool = false
        let mut j: i32 = 0
        while j < cn {
            if str_char_at(chars, j) == c {
                in_set = true
            }
            j += 1
        }
        if !in_set {
            sb_push_char(c)
        }
        i += 1
    }
    print_raw(sb_str())
    return 0
}
