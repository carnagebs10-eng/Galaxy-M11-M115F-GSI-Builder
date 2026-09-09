#!/usr/bin/env bash

set -Eeuo pipefail

SUPER_IMAGE="$1"
OUT="$2"
SUPERUNPACK="${3:-}"

mkdir -p "$OUT"

echo "=========================================="
echo " SUPER IMAGE INSPECTION"
echo "=========================================="

echo
echo "[*] File information:"
file "$SUPER_IMAGE"

echo
echo "[*] Size:"
ls -lh "$SUPER_IMAGE"

echo
echo "[*] Searching for Android logical partition metadata..."

if command -v lpdump >/dev/null 2>&1; then

    lpdump "$SUPER_IMAGE" \
        | tee "$OUT/lpdump.txt"

elif [ -n "$SUPERUNPACK" ]; then

    echo
    echo "[*] BiteTech superunpack found:"
    echo "$SUPERUNPACK"

    echo
    echo "[*] Trying --help..."
    "$SUPERUNPACK" --help 2>&1 \
        | tee "$OUT/superunpack-help.txt" || true

    echo
    echo "The exact superunpack syntax will be determined"
    echo "from the BiteTech installer."
else

    echo "WARNING: no lpdump or superunpack available."
fi

echo
echo "[*] Searching ZIP/base for partition-related information..."

grep -Rai \
    -E "super|system|vendor|product|system_ext|odm|slot" \
    "$OUT/../.." \
    2>/dev/null \
    | head -n 200 \
    | tee "$OUT/partition-search.txt" || true

echo
echo "Super inspection finished."
