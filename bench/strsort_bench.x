module main

// strsort_bench — selection-sort N deterministic strings using the new string
// comparison operators (`<`, `==`), which lower to strcmp. Selection sort is
// O(n²) in comparisons, so this directly stresses the string-comparison codegen
// at scale. Cross-checked against C qsort(strcmp) in strsort_bench.sh.
//
// Usage: strsort_bench [N]   (default 4000)  — prints "<first>..<last>".

fn main(): i32 {
    let mut n: i32 = 4000
    if argc() >= 2 {
        n = str_to_int(argv(1))
    }
    // Build N pseudo-random-order strings (varying length → real strcmp work).
    let items: Vec<String> = vec_new()
    let mut i: i32 = 0
    while i < n {
        items.push(int_to_str((i * 7919) % 1000000))
        i += 1
    }
    // Selection sort by lexicographic string order (`<` → strcmp).
    let mut a: i32 = 0
    while a < n {
        let mut best: i32 = a
        let mut b: i32 = a + 1
        while b < n {
            if items[b] < items[best] {
                best = b
            }
            b += 1
        }
        if best != a {
            let tmp: String = items[a]
            items[a] = items[best]
            items[best] = tmp
        }
        a += 1
    }
    // Print first..last so the bench script can cross-check against C qsort.
    print_raw(items[0])
    print_raw("..")
    print_raw(items[n - 1])
    print_raw("\n")
    return 0
}
