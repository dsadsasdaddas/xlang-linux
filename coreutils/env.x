module main

// env [-i] [NAME=VALUE...] [COMMAND] — list/set environment, optionally run
// a command with the modified environment (GNU env).
//   -i   start with an empty environment
//   NAME=VALUE  set the variable before listing/running
//   COMMAND     run the command with the modified env (via exec_split)

fn main(): i32 {
    let mut clean: i32 = 0
    let mut has_command: i32 = 0
    let mut cmd: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-i") {
            clean = 1
            i = i + 1
        } else {
            let eq: i32 = str_find(a, "=")
            if eq > 0 {
                setenv(str_slice(a, 0, eq), str_slice(a, eq + 1, str_len(a)))
                i = i + 1
            } else {
                cmd = str_concat(cmd, a)
                has_command = 1
                let mut j: i32 = i + 1
                while j < argc() {
                    cmd = str_concat(str_concat(cmd, " "), argv(j))
                    j = j + 1
                }
                break
            }
        }
    }

    if has_command == 1 {
        return exec_split(cmd)
    }

    if clean == 0 {
        let n: i32 = env_count()
        let mut k: i32 = 0
        while k < n {
            print_raw(env_entry(k))
            print_raw("\n")
            k = k + 1
        }
    }
    return 0
}
