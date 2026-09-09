#!/usr/bin/env bash

set -Eeuo pipefail

GSI="$1"
OUT="$2"

mkdir -p "$OUT"

echo "=========================================="
echo " GSI INSPECTION"
echo "=========================================="

echo
echo "[*] GSI file:"
file "$GSI"

echo
echo "[*] GSI size:"
ls -lh "$GSI"

case "$GSI" in

    *.zip)
        echo
        echo "[*] ZIP contents:"
        unzip -l "$GSI" \
            | tee "$OUT/gsi-contents.txt"
        ;;

    *)
        echo
        echo "[*] Treating GSI as image/archive."
        ;;
esac


echo
echo "[*] Extracting GSI if it is a ZIP..."

if file "$GSI" | grep -qi zip; then

    mkdir -p "$OUT/files"

    unzip -q "$GSI" \
        -d "$OUT/files"

fi


echo
echo "[*] Searching for system image..."

SYSTEM_IMG=""

while IFS= read -r f; do
    if [[ "$(basename "$f")" == "system.img" ]]; then
        SYSTEM_IMG="$f"
        break
    fi
done < <(find "$OUT/files" -type f 2>/dev/null)


if [ -n "$SYSTEM_IMG" ]; then

    echo "Found:"
    echo "$SYSTEM_IMG"

    echo
    file "$SYSTEM_IMG"

    echo
    ls -lh "$SYSTEM_IMG"

else

    echo "No system.img found at this stage."
fi


echo
echo "GSI inspection finished."
