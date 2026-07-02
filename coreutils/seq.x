module main

// seq — print numbers. Integer and float modes.
//   seq LAST                     → 1 2 ... LAST
//   seq FIRST LAST              → FIRST ... LAST
//   seq FIRST STEP LAST         → with custom step
// Float mode auto-detected when any arg contains '.'. Uses f64 throughout.
// Handles positive and negative steps (countdown).

fn has_dot(s: String): bool {
    let n: i32 = str_len(s)
    let mut i: i32 = 0
    while i < n {
        if str_char_at(s, i) == 46 { return true }
        i = i + 1
    }
    return false
}

fn main(): i32 {
    if argc() < 2 {
        print_str("usage: seq <last> | <first> <last> | <first> <step> <last>")
        return 1
    }

    let is_float: bool = false
    let mut any_float: i32 = 0
    let mut ai: i32 = 1
    while ai < argc() {
        if has_dot(argv(ai)) { any_float = 1 }
        ai = ai + 1
    }

    if any_float == 1 {
        let mut first: f64 = 1.0
        let mut step: f64 = 1.0
        let mut last: f64 = 0.0
        if argc() == 2 {
            last = str_to_float(argv(1))
        } else {
            if argc() == 3 {
                first = str_to_float(argv(1))
                last = str_to_float(argv(2))
            } else {
                first = str_to_float(argv(1))
                step = str_to_float(argv(2))
                last = str_to_float(argv(3))
            }
        }
        if step == 0.0 {
            print_str("seq: step cannot be zero")
            return 1
        }
        let mut i: f64 = first
        if step > 0.0 {
            while i <= last {
                print_raw(float_to_str(i))
                print_raw("\n")
                i = i + step
            }
        } else {
            while i >= last {
                print_raw(float_to_str(i))
                print_raw("\n")
                i = i + step
            }
        }
    } else {
        let mut first: i32 = 1
        let mut step: i32 = 1
        let mut last: i32 = 0
        if argc() == 2 {
            last = str_to_int(argv(1))
        } else {
            if argc() == 3 {
                first = str_to_int(argv(1))
                last = str_to_int(argv(2))
            } else {
                first = str_to_int(argv(1))
                step = str_to_int(argv(2))
                last = str_to_int(argv(3))
            }
        }
        if step == 0 {
            print_str("seq: step cannot be zero")
            return 1
        }
        let mut i: i32 = first
        if step > 0 {
            while i <= last {
                print_raw(int_to_str(i))
                print_raw("\n")
                i = i + step
            }
        } else {
            while i >= last {
                print_raw(int_to_str(i))
                print_raw("\n")
                i = i + step
            }
        }
    }
    return 0
}
