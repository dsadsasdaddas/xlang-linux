#!/usr/bin/env bash
# Test xsh if/else and full-line comments by piping scripts into xsh vs bash.
#
# Usage: xsh_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/xsh.x -o build/xsh.c >/dev/null 2>&1; cc -O2 -o /tmp/xsh build/xsh.c
SH=/tmp/xsh

cksh() {  # cksh <label> <script>
    local label="$1" script="$2"
    local a b
    a=$(printf '%s\n' "$script" | "$SH" 2>/dev/null)
    b=$(printf '%s\n' "$script" | bash 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       xsh: [$a]"; echo "       bash: [$b]"; FAIL=$((FAIL+1)); fi
}

echo "== if/else vs bash"
cksh "if true  + else"  "if true; then echo a; else echo b; fi"
cksh "if false + else"  "if false; then echo a; else echo b; fi"
cksh "if true  no else" "if [ 3 -lt 5 ]; then echo yes; fi"
cksh "if false no else" "if [ 5 -lt 3 ]; then echo yes; fi"

echo "== full-line comments"
cksh "comment then cmd" $'# this is a comment\necho hi'
cksh "comment only"     $'# just a comment\necho after'

echo "== case/esac vs bash"
cksh "case glob prefix"  'case apple in app*) echo starts ;; *) echo other ;; esac'
cksh "case literal"      'case foo in bar) echo b ;; foo) echo f ;; *) echo o ;; esac'
cksh "case default"      'case zzz in a) echo a ;; b) echo b ;; *) echo def ;; esac'
cksh "case wildcard *"   'case hi in *) echo any ;; esac'
cksh "case + var"        $'v=pear\ncase $v in p*) echo p ;; *) echo x ;; esac'

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
