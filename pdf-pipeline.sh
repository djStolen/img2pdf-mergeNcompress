#!/bin/sh

# pdf-pipeline
#
# POSIX shell script to convert images in a directory into a single naturally ordered PDF
# with optional compression.
#
# Copyright (C) 2026 Your Name
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# ---------------------
# Default configuration
# ---------------------
OUTPUT_PDF="merged_images.pdf"
OUTPUT_COMPRESSED_PDF="merged_compressed_images.pdf"
TEMP_DIR="./temp_pdfs"
CONVERT_QUALITY=100
DO_COMPRESS=1
# ---------------------

print_help() {
    cat <<EOF
pdf-pipeline

Convert images in the current directory into a single, naturally ordered PDF.

USAGE:
  pdf-pipeline [options]

OPTIONS:
  -o <file>        Output PDF file (default: $OUTPUT_PDF)
  -q <quality>     Image quality (0–100, default: $CONVERT_QUALITY)
  --no-compress    Skip compressed PDF output
  -h, --help       Show this help message and exit

SUPPORTED IMAGE TYPES:
  png, jpg, jpeg, gif

REQUIRES:
  ImageMagick (convert)
  pdfunite OR Ghostscript (gs)
EOF
}

# --- Helper: derive compressed filename ---
derive_compressed_name() {
    base=${1%.*}
    ext=${1##*.}

    if [ "$base" = "$ext" ]; then
        echo "${1}.compressed"
    else
        echo "${base}.compressed.${ext}"
    fi
}

# --- Argument parsing ---
while [ $# -gt 0 ]; do
    case "$1" in
        -o)
            OUTPUT_PDF="$2"
            OUTPUT_COMPRESSED_PDF=$(derive_compressed_name "$2")
            shift 2
            ;;
        -q)
            CONVERT_QUALITY="$2"
            shift 2
            ;;
        --no-compress)
            DO_COMPRESS=0
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run 'pdf-pipeline --help' for usage."
            exit 1
            ;;
    esac
done

echo "Starting pdf-pipeline..."
echo "Output PDF: $OUTPUT_PDF"
echo "Image quality: $CONVERT_QUALITY"

# --- Dependency checks ---
command -v convert >/dev/null 2>&1 || {
    echo "Error: ImageMagick 'convert' not found."
    exit 1
}

if command -v pdfunite >/dev/null 2>&1; then
    MERGE_MODE="pdfunite"
elif command -v gs >/dev/null 2>&1; then
    MERGE_MODE="gs"
else
    echo "Error: Neither pdfunite nor Ghostscript found."
    exit 1
fi

# --- Temp dir ---
mkdir -p "$TEMP_DIR" || exit 1

# --- Convert images ---
echo "Converting images..."

find . -maxdepth 1 -type f \( \
    -iname "*.png" -o \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.gif" \
\) -print0 |
sort -zV |
while IFS= read -r -d '' img; do
    base=$(basename "$img")
    name=${base%.*}
    out="$TEMP_DIR/$name.pdf"

    convert "$img" -quality "$CONVERT_QUALITY" "$out" || exit 1
    echo "  -> $base"
done

# --- Verify output ---
if ! find "$TEMP_DIR" -type f -name "*.pdf" | grep -q .; then
    echo "Error: No PDFs were generated."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# --- Merge ---
echo "Merging PDFs using $MERGE_MODE..."

if [ "$MERGE_MODE" = "pdfunite" ]; then
    find "$TEMP_DIR" -type f -name "*.pdf" -print0 |
        sort -zV |
        xargs -0 pdfunite - "$OUTPUT_PDF"
else
    find "$TEMP_DIR" -type f -name "*.pdf" -print0 |
        sort -zV |
        xargs -0 gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite \
            -sOutputFile="$OUTPUT_PDF"
fi

# --- Compress (optional) ---
if [ "$DO_COMPRESS" -eq 1 ] && command -v gs >/dev/null 2>&1; then
    echo "Compressing PDF..."
    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS=/ebook \
       -dNOPAUSE -dQUIET -dBATCH \
       -sOutputFile="$OUTPUT_COMPRESSED_PDF" \
       "$OUTPUT_PDF"
fi

# --- Cleanup ---
rm -rf "$TEMP_DIR"

echo "Done."
echo "Output: $OUTPUT_PDF"
[ "$DO_COMPRESS" -eq 1 ] && [ -f "$OUTPUT_COMPRESSED_PDF" ] && \
    echo "Compressed: $OUTPUT_COMPRESSED_PDF"
