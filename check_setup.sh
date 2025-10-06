#!/bin/bash

echo "Checking BHASHINI_SD setup..."
echo "================================"

# Check Python
echo -n "Python version: "
python --version

# Check venv
if [ -n "$VIRTUAL_ENV" ]; then
    echo "Virtual environment: $VIRTUAL_ENV"
else
    echo "WARNING: No virtual environment active"
    echo "Run: source venv/bin/activate"
fi

# Check directories
echo ""
echo "Directory structure:"
dirs=("input" "output" "speaker_diarization_demo" "Language_diarization_demo" "venv")
for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✓ $dir"
    else
        echo "  ✗ $dir (missing)"
    fi
done

# Check for WAV files
echo ""
wav_count=$(find input -maxdepth 1 -name "*.wav" 2>/dev/null | wc -l)
echo "WAV files in input/: $wav_count"

# Check key Python packages
echo ""
echo "Key packages:"
for pkg in torch torchaudio speechbrain kaldi_io whisper; do
    if python -c "import $pkg" 2>/dev/null; then
        version=$(python -c "import $pkg; print(getattr($pkg, '__version__', 'unknown'))" 2>/dev/null)
        echo "  ✓ $pkg ($version)"
    else
        echo "  ✗ $pkg (not installed)"
    fi
done

# Special check for pyannote.audio
if python -c "import pyannote.audio" 2>/dev/null; then
    echo "  ✓ pyannote.audio"
else
    echo "  ✗ pyannote.audio (not installed)"
fi

# Check Kaldi
echo ""
if [ -d "$HOME/kaldi" ]; then
    echo "✓ Kaldi found at: $HOME/kaldi"
    
    # Check for compiled binaries in multiple locations
    kaldi_compiled=false
    if [ -f "$HOME/kaldi/src/featbin/compute-mfcc-feats" ]; then
        echo "  ✓ Kaldi featbin compiled"
        kaldi_compiled=true
    fi
    if [ -f "$HOME/kaldi/src/bin/copy-feats" ]; then
        echo "  ✓ Kaldi bin compiled"
        kaldi_compiled=true
    fi
    if [ -f "$HOME/kaldi/src/ivectorbin/ivector-extract-online2" ]; then
        echo "  ✓ Kaldi ivectorbin compiled"
        kaldi_compiled=true
    fi
    
    if [ "$kaldi_compiled" = false ]; then
        echo "  ✗ Kaldi binaries not found"
    fi
else
    echo "✗ Kaldi not found"
fi

# Check symbolic links in speaker_diarization_demo
echo ""
echo "Speaker diarization setup:"
if [ -L "speaker_diarization_demo/steps" ]; then
    echo "  ✓ steps symlink exists"
else
    echo "  ✗ steps symlink missing"
fi
if [ -L "speaker_diarization_demo/utils" ]; then
    echo "  ✓ utils symlink exists"
else
    echo "  ✗ utils symlink missing"
fi

echo ""
echo "Setup check complete!"
