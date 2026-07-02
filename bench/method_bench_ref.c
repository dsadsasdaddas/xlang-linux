/* method_bench_ref.c — C baseline for method_bench.x. Same workload: build N
 * points (coords mod 32) and sum x*x+y*y via a free function (the equivalent
 * of xlang's mangled method). Both must agree.
 *
 * Usage: method_bench_ref [N]   (default 2000000)
 */
#include <stdio.h>
#include <stdlib.h>

typedef struct { int x, y; } Point;

static int length_sq(Point p) { return p.x * p.x + p.y * p.y; }

int main(int argc, char **argv) {
    int n = 2000000;
    if (argc >= 2) n = atoi(argv[1]);

    Point *pts = (Point *)malloc((size_t)n * sizeof(Point));
    for (int i = 0; i < n; i++) {
        pts[i].x = i % 32;
        pts[i].y = (i * 7) % 32;
    }
    int total = 0;
    for (int i = 0; i < n; i++) {
        total += length_sq(pts[i]);
    }
    printf("%d\n", total);
    free(pts);
    return 0;
}
