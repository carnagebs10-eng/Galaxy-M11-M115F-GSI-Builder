#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

WORK="$ROOT/work"
DOWNLOADS="$WORK/downloads"
BASE="$WORK/base"
GSI="$WORK/gsi"
SUPER="$WORK/super"
OUTPUT="$WORK/output"
LOGS="$WORK/logs"

mkdir -p \
    "$DOWNLOADS" \
    "$BASE" \
    "$GSI" \
    "$SUPER" \
    "$OUTPUT" \
    "$LOGS"

exec > >(tee "$LOGS/build.log") 2>&1

echo "=========================================="
echo " M115F GSI BUILDER"
echo "=========================================="

echo
echo "[*] ROM       : ${ROM_NAME:-unknown}"
echo "[*] Mode      : ${BUILD_MODE:-inspect}"
echo "[*] Device    : M115F / m11q"
echo

if [[ -z "${BASE_URL:-}" ]]; then
    echo "ERROR: BASE_URL is missing"
    exit 1
fi

if [[ -z "${GSI_URL:-}" ]]; then
    echo "ERROR: GSI_URL is missing"
    exit 1
fi

echo "[1/8] Checking disk space..."

AVAILABLE_KB=$(df -Pk "$WORK" | awk 'NR==2 {print $4}')
AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))

echo "Available: ${AVAILABLE_GB} GB"

if [ "$AVAILABLE_GB" -lt 10 ]; then
    echo
    echo "WARNING:"
    echo "The GitHub runner has too little free space."
    echo "Your BiteTech super.new.img is very large."
    echo
    echo "Build stopped before downloading large files."
    exit 1
fi


echo
echo "[2/8] Downloading BiteTech base..."

BASE_ZIP="$DOWNLOADS/base.zip"

curl \
    --fail \
    --location \
    --retry 3 \
    --continue-at - \
    "$BASE_URL" \
    -o "$BASE_ZIP"

echo
echo "[3/8] Downloading GSI..."

GSI_FILE="$DOWNLOADS/gsi"

curl \
    --fail \
    --location \
    --retry 3 \
    --continue-at - \
    "$GSI_URL" \
    -o "$GSI_FILE"

echo
echo "[4/8] Inspecting downloaded files..."

file "$BASE_ZIP"
file "$GSI_FILE"

echo
echo "[5/8] Extracting base ZIP..."

unzip -q "$BASE_ZIP" -d "$BASE"

echo
echo "Base contents:"
find "$BASE" -maxdepth 4 -type f | sort


echo
echo "[6/8] Checking required M115F files..."

if [ ! -f "$BASE/boot.img" ]; then
    echo "ERROR: boot.img was not found."
    exit 1
fi

if [ ! -f "$BASE/super.new.img" ]; then
    echo "ERROR: super.new.img was not found."
    exit 1
fi

echo "boot.img        OK"
echo "super.new.img   OK"


echo
echo "[7/8] Locating BiteTech dynamic-partition tools..."

TOOL_DIR="$BASE/META-INF/addons/extra"

if [ -f "$TOOL_DIR/superunpack" ]; then
    chmod +x "$TOOL_DIR/superunpack"
    SUPERUNPACK="$TOOL_DIR/superunpack"
elif [ -f "$TOOL_DIR/superunpack" ]; then
    SUPERUNPACK="$TOOL_DIR/superunpack"
else
    SUPERUNPACK=""
fi

if [ -f "$TOOL_DIR/superrepack" ]; then
    chmod +x "$TOOL_DIR/superrepack"
    SUPERREPACK="$TOOL_DIR/superrepack"
else
    SUPERREPACK=""
fi

echo "superunpack: ${SUPERUNPACK:-NOT FOUND}"
echo "superrepack: ${SUPERREPACK:-NOT FOUND}"


echo
echo "[8/8] Inspecting super image..."

chmod +x scripts/inspect_super.sh
scripts/inspect_super.sh \
    "$BASE/super.new.img" \
    "$SUPER" \
    "$SUPERUNPACK"


echo
echo "=========================================="
echo " GSI INSPECTION"
echo "=========================================="

chmod +x scripts/inspect_gsi.sh
scripts/inspect_gsi.sh "$GSI_FILE" "$GSI"


echo
echo "=========================================="
echo " BUILD MODE"
echo "=========================================="

if [ "${BUILD_MODE:-inspect}" = "inspect" ]; then

    echo
    echo "Inspection completed."
    echo
    echo "The builder deliberately stopped before modifying"
    echo "the M115F super image."
    echo
    echo "This is intentional until the BiteTech updater-script"
    echo "and actual super layout have been verified."
    echo

    exit 0
fi


if [ "${BUILD_MODE:-inspect}" = "build" ]; then

    echo
    echo "BUILD MODE ENABLED"
    echo

    chmod +x scripts/convert_gsi.sh

    scripts/convert_gsi.sh \
        "$BASE" \
        "$GSI" \
        "$SUPER" \
        "$OUTPUT" \
        "$ROM_NAME"

fi

echo
echo "DONE."
