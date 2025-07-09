#!/bin/bash

# Usage: ./script.sh file1.svg file2.svg ...

for file in "$@"; do
    # Get base name and strip extension
    basename="${file##*/}"
    name="${basename%.svg}"

    # Export PNG with width = 300 pixels
    inkscape "$file" --export-type=png --export-filename="${name}.png" --export-width=300
done
