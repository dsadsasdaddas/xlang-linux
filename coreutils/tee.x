module main

// tee [-a] <file>... — copy stdin to each file AND stdout (GNU tee).
//   -a   append to files instead of overwriting
// Multiple files supported.

fn main(): i32 {
    let mut append: i32 = 0
    let files: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut k: i32 = 1
                while k < str_len(a) {
                    if str_char_at(a, k) == 97 { append = 1 }
                    k = k + 1
                }
                i = i + 1
            } else {
                files.push(a)
                i = i + 1
            }
        } else {
            files.push(a)
            i = i + 1
        }
    }
    let s: String = read_stdin()
    let nf: i32 = vec_len(files)
    let mut k: i32 = 0
    while k < nf {
        if append == 1 {
            let old: String = read_file(files[k])
            write_file(files[k], str_concat(old, s))
        } else {
            write_file(files[k], s)
        }
        k = k + 1
    }
    print_raw(s)
    return 0
}
