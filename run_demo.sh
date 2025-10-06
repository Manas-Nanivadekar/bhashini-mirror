#!/bin/bash

set -e  # Exit on error

## Path variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SD_FOLDER="${SCRIPT_DIR}/speaker_diarization_demo"
INPUT_FOLDER="${SCRIPT_DIR}/input"
OUTPUT_FOLDER="${SCRIPT_DIR}/output"
LOG_FILE="${SCRIPT_DIR}/run_demo.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Start logging
log "Starting speaker diarization demo..."
log "Script directory: $SCRIPT_DIR"

# Check if virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
    warn "Virtual environment not activated."
    warn "Please run: source venv/bin/activate"
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    log "Using virtual environment: $VIRTUAL_ENV"
fi

# Create directories if they don't exist
log "Checking directories..."
mkdir -p "$INPUT_FOLDER"
mkdir -p "$OUTPUT_FOLDER"

# Check if speaker_diarization_demo exists
if [ ! -d "$SD_FOLDER" ]; then
    error "Speaker diarization folder not found: $SD_FOLDER"
    exit 1
fi

# Check if input folder has WAV files
wav_count=$(find "$INPUT_FOLDER" -maxdepth 1 -name "*.wav" -type f 2>/dev/null | wc -l)
if [ "$wav_count" -eq 0 ]; then
    error "No WAV files found in: $INPUT_FOLDER"
    error "Please place your WAV files in the input folder and try again."
    exit 1
fi

log "Found $wav_count WAV file(s) to process"

echo "####################################################################"
echo "Input folder: $INPUT_FOLDER"
echo "Output folder: $OUTPUT_FOLDER"
echo "Processing $wav_count WAV file(s)..."
echo "####################################################################"

# Process each WAV file
processed=0
failed=0

for file in "$INPUT_FOLDER"/*.wav; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        nameonly="${filename%.wav}"
        
        log "Processing: $filename"
        
        # Change to speaker diarization directory
        cd "$SD_FOLDER" || { error "Failed to change to $SD_FOLDER"; exit 1; }
        
        # Run the diarization script
        if ./run_spectral_file.sh "$file" "$nameonly" >> "$LOG_FILE" 2>&1; then
            log "Successfully processed: $filename"
            
            # Copy RTTM file to output folder
            rttm_source="$SD_FOLDER/exp/${nameonly}_diarization_vbhmm_spectral/per_file_rttm/${nameonly}.rttm"
            
            if [ -f "$rttm_source" ]; then
                cp "$rttm_source" "$OUTPUT_FOLDER/" || warn "Failed to copy RTTM for $filename"
                log "RTTM saved: ${nameonly}.rttm"
                ((processed++))
            else
                warn "RTTM file not found for $filename at: $rttm_source"
                ((failed++))
            fi
        else
            error "Failed to process: $filename (check $LOG_FILE for details)"
            ((failed++))
        fi
        
        # Return to main directory
        cd "$SCRIPT_DIR" || exit 1
        
        echo "-----------------------------------"
    fi
done

# Summary
echo "####################################################################"
log "Processing complete!"
log "Successfully processed: $processed file(s)"
if [ "$failed" -gt 0 ]; then
    warn "Failed: $failed file(s)"
fi
log "RTTM files saved in: $OUTPUT_FOLDER"
log "Log file: $LOG_FILE"
echo "####################################################################"
