#!/usr/bin/env bash

set -Eeuo pipefail

BASE="$1"
GSI="$2"
SUPER="$3"
OUTPUT="$4"
ROM_NAME="$5"

echo "=========================================="
echo " M115F GSI CONVERSION"
echo "=========================================="

echo
echo "Base : $BASE"
echo "GSI  : $GSI"
echo "Super: $SUPER"
echo "Out  : $OUTPUT"

echo
echo "IMPORTANT"
echo "--------"
echo "The final conversion is intentionally disabled."
echo
echo "Before rebuilding super.new.img we need:"
echo
echo "  1. BiteTech updater-script"
echo "  2. Actual super partition metadata"
echo "  3. Exact superunpack syntax"
echo "  4. Exact superrepack syntax"
echo "  5. Which logical partitions BiteTech expects"
echo "  6. GSI partition layout"
echo "  7. Whether AVB metadata must be preserved"
echo
echo "Without these, automatically rebuilding super could"
echo "produce an unbootable M115F ROM."
echo

exit 2
