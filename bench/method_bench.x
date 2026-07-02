module main

// method_bench — dogfood `impl` methods at scale: sum length_sq() over N points
// in a Vec<Point>, calling the method once per element. Proves method-call
// dispatch (→ mangled free function) has no overhead vs a hand-written C loop.
// Cross-checked against method_bench_ref.c in method_bench.sh.
//
// Usage: method_bench [N]   (default 2000000)  — prints the summed length².

struct Point {
    x: i32
    y: i32
}

impl Point {
    fn length_sq(self: Point): i32 {
        return self.x * self.x + self.y * self.y
    }
}

fn main(): i32 {
    let mut n: i32 = 2000000
    if argc() >= 2 {
        n = str_to_int(argv(1))
    }
    // Build N deterministic points. Coords are mod 32 so the summed length²
    // fits comfortably in i32 even for large N.
    let pts: Vec<Point> = vec_new()
    let mut i: i32 = 0
    while i < n {
        pts.push(Point { x: i % 32, y: (i * 7) % 32 })
        i += 1
    }
    // Sum length_sq() via a method call per element.
    let mut total: i32 = 0
    for p in pts {
        total += p.length_sq()
    }
    print_raw(int_to_str(total))
    print_raw("\n")
    return 0
}
