# pdf-pipeline

POSIX shell script to convert images in a directory into a single naturally ordered PDF, with optional compression.

## Features

- Converts images (png, jpg, jpeg, gif) in the current directory to PDF.
- Automatically merges all PDFs in natural sort order.
- Optional PDF compression.
- Fully POSIX-compliant; works on Linux/macOS with standard tools.
- CLI options for output file, image quality, and compression control.
- Smart automatic compressed filename derivation.

## Requirements

- ImageMagick (convert)
- Either:
  - pdfunite OR
  - Ghostscript (gs)

## Installation

1. Clone the repository:

   git clone https://github.com/yourusername/pdf-pipeline.git
   cd pdf-pipeline

2. Make the script executable:

   chmod +x pdf-pipeline.sh

3. Optionally, move it to a directory in your PATH:

   sudo mv pdf-pipeline.sh /usr/local/bin/pdf-pipeline

## Usage

   pdf-pipeline [options]

### Options

- -o <file>        Output PDF file (default: merged_images.pdf)
- -q <quality>     Image quality for conversion (0–100, default: 100)
- --no-compress    Skip creating a compressed PDF
- -h, --help       Show help message

### Examples

Default behavior:

   pdf-pipeline

Creates:
- merged_images.pdf
- merged_compressed_images.pdf

Custom output file:

   pdf-pipeline -o book.pdf

Creates:
- book.pdf
- book.compressed.pdf

Custom quality, skip compression:

   pdf-pipeline -q 75 --no-compress

Creates only merged_images.pdf.

## License

This project is licensed under the GPL-2.0 License. See the LICENSE file for details.
