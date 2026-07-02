module main

// du [-s] [-b] [dir]... — disk usage (GNU du subset).
//   -s   summary only (one total per dir, no per-subdir breakdown)
//   -b   bytes (default; the only unit)
// Recursive byte count via file_size (stat). Multiple dirs supported.

fn du_dir(dir: String): i32 {
    let n: i32 = dir_count(dir)
    let mut i: i32 = 0
    let mut total: i32 = 0
    while i < n {
        let entry: String = dir_entry(dir, i)
        if str_len(entry) > 0 {
            if str_char_at(entry, 0) != 46 {
                let path: String = str_concat(str_concat(dir, "/"), entry)
                total = total + file_size(path)
                if is_dir(path) == 1 {
                    total = total + du_dir(path)
                }
            }
        }
        i = i + 1
    }
    return total
}

fn main(): i32 {
    let mut summary: i32 = 0
    let dirs: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut j: i32 = 1
                while j < str_len(a) {
                    if str_char_at(a, j) == 115 { summary = 1 }
                    if str_char_at(a, j) == 98 { summary = 0 }
                    j = j + 1
                }
                i = i + 1
            } else {
                dirs.push(a)
                i = i + 1
            }
        } else {
            dirs.push(a)
            i = i + 1
        }
    }
    let nd: i32 = vec_len(dirs)
    if nd == 0 {
        dirs.push(".")
    }
    let mut k: i32 = 0
    while k < vec_len(dirs) {
        let d: String = dirs[k]
        let total: i32 = du_dir(d)
        print_raw(int_to_str(total))
        print_raw("\t")
        print_raw(d)
        print_raw("\n")
        k = k + 1
    }
    return 0
}
