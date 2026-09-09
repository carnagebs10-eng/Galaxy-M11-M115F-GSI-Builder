#!/usr/bin/env bash
set -euo pipefail

echo "========================================"
echo " M115F GSI Builder"
echo "========================================"

# --------------------------------------------------
# Configuration
# --------------------------------------------------

WORK_DIR="${GITHUB_WORKSPACE:-$(pwd)}/work"

BASE_DIR="$WORK_DIR/base"
GSI_DIR="$WORK_DIR/gsi"
TOOLS_DIR="$WORK_DIR/tools"
OUTPUT_DIR="$WORK_DIR/output"

BASE_ZIP="$WORK_DIR/base.zip"
GSI_FILE="$WORK_DIR/gsi_download"

mkdir -p "$WORK_DIR" "$BASE_DIR" "$GSI_DIR" "$TOOLS_DIR" "$OUTPUT_DIR"

echo
echo "[1/8] Checking environment..."

command -v curl >/dev/null || {
    echo "ERROR: curl is missing."
    exit 1
}

command -v unzip >/dev/null || {
    echo "ERROR: unzip is missing."
    exit 1
}

command -v xz >/dev/null || {
    echo "ERROR: xz is missing."
    exit 1
}

echo "Workspace: $WORK_DIR"

# --------------------------------------------------
# Required variables
# --------------------------------------------------

: "${BASE_URL:?BASE_URL is required}"
: "${GSI_URL:?GSI_URL is required}"

ROM_NAME="${ROM_NAME:-AxionOS-2.7}"
BUILD_MODE="${BUILD_MODE:-inspect}"

echo "ROM name:   $ROM_NAME"
echo "Build mode: $BUILD_MODE"

# --------------------------------------------------
# Download base ROM
# --------------------------------------------------

echo
echo "[2/8] Downloading M115F base ROM..."

rm -f "$BASE_ZIP"

curl -L \
    --fail \
    --retry 3 \
    --retry-delay 5 \
    -o "$BASE_ZIP" \
    "$BASE_URL"

echo "Base downloaded:"
ls -lh "$BASE_ZIP"

# --------------------------------------------------
# Download GSI
# --------------------------------------------------

echo
echo "[3/8] Downloading GSI..."

rm -f "$GSI_FILE"

curl -L \
    --fail \
    --retry 3 \
    --retry-delay 5 \
    -o "$GSI_FILE" \
    "$GSI_URL"

echo "GSI downloaded:"
ls -lh "$GSI_FILE"

# --------------------------------------------------
# Extract base ROM
# --------------------------------------------------

echo
echo "[4/8] Extracting base ZIP..."

rm -rf "$BASE_DIR"
mkdir -p "$BASE_DIR"

unzip -q "$BASE_ZIP" -d "$BASE_DIR"

echo
echo "Base contents:"
find "$BASE_DIR" -maxdepth 3 -type f -printf '%p\n' | sort

# --------------------------------------------------
# Handle compressed super image
# --------------------------------------------------

echo
echo "[5/8] Checking and preparing super image..."

# BiteTech base uses:
#
#     super.new.img.xz
#
# Convert it to:
#
#     super.new.img
#
# before inspection.

if [ -f "$BASE_DIR/super.new.img.xz" ]; then
    echo "Found super.new.img.xz"
    echo "Decompressing..."

    xz -d -f "$BASE_DIR/super.new.img.xz"

    echo "Decompressed successfully."
fi

# Also handle the possibility that the ZIP places it
# somewhere else.

if [ ! -f "$BASE_DIR/super.new.img" ]; then
    FOUND_SUPER="$(find "$BASE_DIR" -type f -name 'super.new.img' -print -quit || true)"

    if [ -n "$FOUND_SUPER" ]; then
        echo "Found super image at:"
        echo "$FOUND_SUPER"

        cp "$FOUND_SUPER" "$BASE_DIR/super.new.img"
    fi
fi

# --------------------------------------------------
# Check required M115F files
# --------------------------------------------------

echo
echo "[6/8] Checking required M115F files..."

if [ ! -f "$BASE_DIR/boot.img" ]; then
    echo "ERROR: boot.img was not found."
    exit 1
fi

if [ ! -f "$BASE_DIR/super.new.img" ]; then
    echo "ERROR: super.new.img was not found."
    echo
    echo "Files matching super:"
    find "$BASE_DIR" -type f -iname '*super*' -printf '%p\n' || true
    exit 1
fi

echo
echo "boot.img:"
ls -lh "$BASE_DIR/boot.img"

echo
echo "super.new.img:"
ls -lh "$BASE_DIR/super.new.img"

# --------------------------------------------------
# Extract BiteTech tools
# --------------------------------------------------

echo
echo "[7/8] Checking BiteTech tools..."

EXTRA_ZIP="$BASE_DIR/META-INF/addons/extra.zip"

if [ -f "$EXTRA_ZIP" ]; then
    echo "Found:"
    echo "$EXTRA_ZIP"

    rm -rf "$TOOLS_DIR"
    mkdir -p "$TOOLS_DIR"

    unzip -q "$EXTRA_ZIP" -d "$TOOLS_DIR"

    echo
    echo "BiteTech tools:"
    find "$TOOLS_DIR" -maxdepth 3 -type f -printf '%p\n' | sort
else
    echo "WARNING: META-INF/addons/extra.zip was not found."
fi

# --------------------------------------------------
# Run inspection
# --------------------------------------------------

echo
echo "[8/8] Running inspection..."

chmod +x scripts/*.sh 2>/dev/null || true

echo
echo "========================================"
echo " BASE SUPER INSPECTION"
echo "========================================"

if [ -x "./scripts/inspect_super.sh" ]; then
    BASE_SUPER="$BASE_DIR/super.new.img" \
    TOOLS_DIR="$TOOLS_DIR" \
    ./scripts/inspect_super.sh
else
    echo "WARNING: inspect_super.sh not found."
fi

echo
echo "========================================"
echo " GSI INSPECTION"
echo "========================================"

if [ -x "./scripts/inspect_gsi.sh" ]; then
    GSI_INPUT="$GSI_FILE" \
    GSI_DIR="$GSI_DIR" \
    ./scripts/inspect_gsi.sh
else
    echo "WARNING: inspect_gsi.sh not found."
fi

# --------------------------------------------------
# Build mode
# --------------------------------------------------

if [ "$BUILD_MODE" = "build" ]; then

    echo
    echo "========================================"
    echo " BUILD MODE"
    echo "========================================"

    if [ -x "./scripts/convert_gsi.sh" ]; then

        BASE_DIR="$BASE_DIR" \
        GSI_DIR="$GSI_DIR" \
        TOOLS_DIR="$TOOLS_DIR" \
        OUTPUT_DIR="$OUTPUT_DIR" \
        ROM_NAME="$ROM_NAME" \
        ./scripts/convert_gsi.sh

    else
        echo "ERROR: convert_gsi.sh not found."
        exit 1
    fi

else

    echo
    echo "========================================"
    echo " INSPECTION COMPLETE"
    echo "========================================"
    echo
    echo "Build mode was '$BUILD_MODE'."
    echo "No ROM was modified or created."
    echo
    echo "Use build mode only after the super/GSI"
    echo "inspection has been verified."

fi

echo
echo "========================================"
echo " DONE"
echo "========================================"
