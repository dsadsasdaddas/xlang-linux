// demo_userland.xsh — showcases the pure xlang userland end-to-end.
// Run: PATH=~/xc ~/xc/xsh < examples/demo_userland.xsh
// Demonstrates: seq, awk, grep, sed, sort, uniq, wc, sha256sum, printf,
// functions, if/while/[ ], $((expr)), $(), pipes, redirects.

// Generate test data
seq 1 1000 | awk "{print \"record-\"\$1\" status-\"\$1%4\" value-\"\$1}" > /tmp/demo_data.txt

echo "=== xlang Userland Demo ==="
total=$(wc -l < /tmp/demo_data.txt)
echo "Records: $total"

echo "=== Status Distribution ==="
grep status < /tmp/demo_data.txt | sed "s/.*status-/status-/" | sed "s/ .*//" | sort | uniq -c

echo "=== SHA-256 of dataset ==="
sha256sum /tmp/demo_data.txt

echo "=== Conditional ==="
if [ $total -gt 500 ]
then echo "Large dataset ($total records)"
fi

echo "=== Arithmetic ==="
echo "Sum of 1..100 = $((100 * 101 / 2))"

echo "=== Compound command ==="
[ $total -gt 0 ] && echo "Data exists" || echo "Empty"

echo "=== Pipeline ==="
grep status-0 < /tmp/demo_data.txt | wc -l
echo "records with status-0"

rm -f /tmp/demo_data.txt
echo "=== Demo Complete ==="
