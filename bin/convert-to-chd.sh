#!/bin/zsh

# Function to display usage instructions
usage() {
    echo "Usage: $0 [-h] -d <input_folder>"
    echo ""
    echo "Options:"
    echo "  -h                 Show this help message and exit."
    echo "  -d <input_folder>  Specify the folder to process (required)."
    echo ""
    echo "Description:"
    echo "  This script converts .cue, .gdi, and .iso files to .chd format using chdman."
    echo "  The resulting .chd files will be placed in the same folder as their input files."
    exit 1
}

# Check if chdman is installed
if ! command -v chdman &> /dev/null; then
    echo "Error: chdman is not installed. Please install it first."
    exit 1
fi

# Parse command-line arguments
INPUT_FOLDER=""
while getopts "hd:" opt; do
    case $opt in
        h) usage ;;
        d) INPUT_FOLDER="$OPTARG" ;;
        *) usage ;;
    esac
done

# Validate that the input folder is provided
if [[ -z "$INPUT_FOLDER" ]]; then
    echo "Error: Input folder is required."
    usage
fi

# Validate that the input folder exists
if [[ ! -d "$INPUT_FOLDER" ]]; then
    echo "Error: Input folder does not exist: $INPUT_FOLDER"
    exit 1
fi

# Traverse the input folder recursively
find "$INPUT_FOLDER" -type f \( -name "*.cue" -o -name "*.gdi" -o -name "*.iso" \) | while read -r FILE; do
    # Extract the base name (without extension) and directory of the file
    BASENAME="${FILE:t:r}"  # Get the base name without extension
    DIRNAME="${FILE:h}"     # Get the directory path

    # Create the .chd file in the same directory as the input file
    OUTPUT_FILE="$DIRNAME/$BASENAME.chd"

    echo "Processing: $FILE"
    chdman createcd -i "$FILE" -o "$OUTPUT_FILE"
done

echo "All files processed. Converted .chd files are in their respective input folders."
