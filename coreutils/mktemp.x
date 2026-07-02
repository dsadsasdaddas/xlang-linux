module main

// mktemp [-d] [TEMPLATE] — create a temporary file or directory (GNU mktemp).
//   -d   create a directory instead of a file
//   TEMPLATE  trailing X's replaced with random digits; default
//             /tmp/xlang_tmp_PID_RND

fn make_random_suffix(len: i32): String {
    let digits: String = "0123456789"
    sb_new()
    let mut i: i32 = 0
    while i < len {
        let r: i32 = random_int(10)
        sb_push(str_slice(digits, r, r + 1))
        i = i + 1
    }
    return str_slice(sb_str(), 0, str_len(sb_str()))
}

fn expand_template(tpl: String): String {
    let n: i32 = str_len(tpl)
    let mut x_count: i32 = 0
    let mut i: i32 = n - 1
    while i >= 0 {
        if str_char_at(tpl, i) == 88 {
            x_count = x_count + 1
        } else {
            break
        }
        i = i - 1
    }
    if x_count == 0 { return tpl }
    let prefix: String = str_slice(tpl, 0, n - x_count)
    return str_concat(prefix, make_random_suffix(x_count))
}

fn main(): i32 {
    let mut make_dir: i32 = 0
    let mut template: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-d") {
            make_dir = 1
            i = i + 1
        } else {
            if str_char_at(a, 0) == 45 {
                i = i + 1
            } else {
                template = a
                i = i + 1
            }
        }
    }
    random_seed()
    if str_len(template) == 0 {
        let pid: i32 = getpid()
        let rnd: i32 = random_int(999999)
        template = str_concat(str_concat(str_concat("/tmp/xlang_tmp_", int_to_str(pid)), "_"), int_to_str(rnd))
    } else {
        template = expand_template(template)
    }

    if make_dir == 1 {
        make_dir(template)
        print_raw(template)
        print_raw("\n")
    } else {
        write_file(template, "")
        print_raw(template)
        print_raw("\n")
    }
    return 0
}
