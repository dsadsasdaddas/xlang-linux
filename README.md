# xlang-linux — Linux userland replication in X Language

**79 coreutils + a shell**, all written in [xlang](https://github.com/dsadsasdaddas/xlang), compiled to C, verified against GNU on a Linux server.

## Coreutils

```
arch base64 basename cat catb cate cats chmod clear comm cp cut date dirname du echo env expand expr factor false find fold free grep head hostname kill link ln logname longestline ls mkdir mkfifo mv nl nproc od paste printenv ps pwd readlink realpath rev rm rmdir fmt sed seq showall shuf sleep sort split stat tac tail tee test touch tr trdelete true truncate tty uname unexpand uniq uniqc uniqd uptime wc whoami xsh yes 
```

## Shell

`xsh` — a minimal shell with pwd/cd builtins + system() command delegation.

## Build

Requires the [xlang compiler](https://github.com/dsadsasdaddas/xlang):
```sh
xlangc c coreutils/cat.x && cc -O2 -o cat cat.c && echo hello | ./cat
```

## Methodology

Built iteratively: **replicate → hit a limitation → modify xlang → implement → verify**.
