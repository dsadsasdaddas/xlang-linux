# xlang-linux — Performance vs GNU coreutils

All numbers from `wzu` (10.132.218.11, 64-core Ubuntu 22.04). xlang compiled `.x → C (-O2)`. Each tool verified **byte-identical** to its GNU counterpart before timing.

## Large-scale stress test (the headline)

`tr -d` and `base64` (encode + `-d` decode) on 1M generated lines. These
uncovered and then fixed xlang's worst performance traps.

| tool (1M lines) | xlang | GNU | ratio |
|---|---|---|---|
| `tr -d aeiou`   |  58 ms |  24 ms | 2.4× |
| `base64`        |  59 ms |  14 ms | 4.2× |
| `base64 -d`     | 124 ms |  67 ms | 1.85× |

All outputs verified byte-identical to GNU (`cmp`). `base64 -d` text round-trip
(`encode | decode`) is byte-identical over 1M lines.

> Known limitation: `base64 -d` of input that decodes to bytes containing
> embedded NULs (0x00) is truncated at the first NUL, because xlang strings are
> NUL-terminated C strings. Text input (the common case) is unaffected.

## The three fixes (each was a 10–1000× trap)

Discovered by stress-testing at 100k lines. Each was a genuine **O(n²)** in the xlang runtime, not the algorithm.

1. **`str_concat` accumulation is O(n²).** `base64` built output one piece at a time with `str_concat(out, piece)`, copying the whole output each call → **114 s @100k**.
   → Added **StringBuilder builtins** (`sb_new` / `sb_push` / `sb_str`): a global growable buffer, O(1) amortized append.

2. **`str_slice` called `strlen` on every invocation.** `tr -d` sliced one char at a time off the giant input string; each `str_slice(s,i,i+1)` ran `strlen(s)` (the whole string) for a bounds clamp → **163 s @100k**.
   → Dropped the clamp; `memcpy(out, s+start, end-start)` needs no length.

3. **Per-element malloc.** Even O(n), `str_slice`/`sb_push(str)` allocated a fresh heap string per char/digit; GNU works in-place in one buffer → still 13–18× slower.
   → Added **`sb_push_char(int)`**: append one byte, zero allocation. Rewrote `tr -d` and `base64` to push chars directly.

4. **Linear set scan.** `tr -d` checked each char against the delete set with an O(|set|) inner loop.
   → Built a **256-entry `Vec<i32>` lookup table** (xlang generics work for `i32`, not just `String`): O(1) per-char membership.

### Cumulative effect on `tr -d` @1M lines

```
163 000 ms   (str_slice strlen trap)        — vs GNU ~24 ms
      132 ms   (StringBuilder + drop strlen clamp)   @100k
       78 ms   (sb_push_char — zero per-char alloc)  @1M
       58 ms   (Vec<i32> lookup table)               @1M, 2.4× GNU
```
A **~2 800× speedup**, ending within 2.4× of GNU.

## Pipeline benchmark

A typical text-processing pipeline (`cat | grep | sort | uniq | wc`) on 10k lines runs at **~1.3× GNU** end-to-end — competitive.

## Methodology

- Inputs generated with `seq | while read`.
- Timed with `date +%s%N` around the pipeline.
- Correctness gated first: `diff <(xlang…) <(gnu…)` must be empty (base64 compared against `base64 -w0` with trailing newline stripped).
- The xlang compiler itself is rebuilt on the server (`cargo build --release`); generated C compiled with `cc -O2`.
