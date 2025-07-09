#!/bin/bash

# Exit on any error
set -e

# Define output name
OUTPUT_NAME="3Dfiles"

# Run Nuitka with full options (inline instead of .nuitka-project)
nuitka 3Dfiles.py \
  --standalone \
  --onefile \
  --enable-plugin=pyside6 \
  --include-module=FileModel \
  --include-module=thumbnail \
  --include-data-dir=ui=ui \
  --output-filename="$OUTPUT_NAME" \

# Done
echo "✅ Build complete: ./$OUTPUT_NAME.bin"
