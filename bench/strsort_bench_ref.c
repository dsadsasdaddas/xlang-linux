/* strsort_bench_ref.c — C baseline for strsort_bench.x using the SAME O(n²)
 * selection-sort algorithm (not qsort), so the timing gap is pure codegen,
 * not algorithm. Builds the same N pseudo-random strings, sorts with strcmp,
 * prints "<first>..<last>". Both must agree.
 *
 * Usage: strsort_bench_ref [N]   (default 4000)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
    int n = 4000;
    if (argc >= 2) n = atoi(argv[1]);

    char **items = (char **)malloc((size_t)n * sizeof(char *));
    char buf[32];
    for (int i = 0; i < n; i++) {
        snprintf(buf, sizeof(buf), "%d", (i * 7919) % 1000000);
        items[i] = strdup(buf);
    }
    /* Selection sort — identical algorithm to strsort_bench.x. */
    for (int a = 0; a < n; a++) {
        int best = a;
        for (int b = a + 1; b < n; b++) {
            if (strcmp(items[b], items[best]) < 0) best = b;
        }
        if (best != a) {
            char *tmp = items[a];
            items[a] = items[best];
            items[best] = tmp;
        }
    }
    printf("%s..%s\n", items[0], items[n - 1]);
    for (int i = 0; i < n; i++) free(items[i]);
    free(items);
    return 0;
}
