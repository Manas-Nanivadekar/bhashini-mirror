import os
import subprocess
import argparse
import sys

# Configuration
PYTHON = "python3"
SEG_DUR = 10    # maximum segment duration in sec
SEG_SHIFT = 0.4 # shift to the next segment in sec
SEG_OVRLAP = SEG_DUR - SEG_SHIFT

# List of required scripts
REQUIRED_FILES = [
    "VAD_kaldi_segments.py",
    "create_subseg.py",
    "feat_extr.py",
    "clustering.py"
]

def check_required_files(files):
    missing_files = [f for f in files if not os.path.isfile(f)]
    if missing_files:
        print(f"Error: The following required files are missing: {', '.join(missing_files)}")
        sys.exit(1)

def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running command: {command}")
        print(result.stderr)
    else:
        print(result.stdout)

def main(audio_path, output_dir=None):
    check_required_files(REQUIRED_FILES)

    kaldi_segments = os.path.basename(audio_path).split('.')[0]
    
    if output_dir is None:
        output_dir = os.path.abspath(kaldi_segments)
    else:
        output_dir = os.path.abspath(output_dir)

    # Define paths within the output directory
    vad_kaldi_path = os.path.join(output_dir, f'{kaldi_segments}_pyannote_segment.txt')
    subseg_subdir = 'dev_subseg'
    feat_subdir = 'dev_feat'
    rttm_subdir = 'dev_rttm'

    path_subsegs = os.path.join(output_dir, subseg_subdir)
    feat_output_dir = os.path.join(output_dir, feat_subdir)
    rttm_output_dir = os.path.join(output_dir, rttm_subdir)

    # Create necessary subdirectories
    os.makedirs(path_subsegs, exist_ok=True)
    os.makedirs(feat_output_dir, exist_ok=True)
    os.makedirs(rttm_output_dir, exist_ok=True)

    print(f"Output directory: {output_dir}")

    # Run VAD
    print("Running VAD...")
    run_command(f"{PYTHON} VAD_kaldi_segments.py {audio_path} {output_dir}")

    # Check if VAD output exists
    if not os.path.isfile(vad_kaldi_path):
        print(f"Error: VAD output file not found: {vad_kaldi_path}")
        sys.exit(1)
    else:
        print(f"VAD output file found: {vad_kaldi_path}")

    # Create subsegments
    print(f"Creating subsegments in: {path_subsegs}...")
    run_command(f"{PYTHON} create_subseg.py --input_file {vad_kaldi_path} --out_subsegments_folder {path_subsegs} --max-segment-duration {SEG_DUR} --overlap-duration {SEG_OVRLAP} --max-remaining-duration {SEG_DUR} --constant-duration False")

    subseg_file = os.path.join(path_subsegs, f'subsegments_{kaldi_segments}_pyannote_segment.txt')
    # Check if subsegments file exists
    if not os.path.isfile(subseg_file):
        print(f"Error: Subsegments file not found: {subseg_file}")
        sys.exit(1)
    else:
        print(f"Subsegments file found: {subseg_file}")

    # Extract features
    print(f"Extracting features to: {feat_output_dir}...")
    run_command(f"{PYTHON} feat_extr.py --aud_path {audio_path} --out_dir {feat_output_dir} --seg_dir {path_subsegs}")

    emb_file = os.path.join(feat_output_dir, f'{kaldi_segments}_output.npy')
    # Check if embedding file exists
    if not os.path.isfile(emb_file):
        print(f"Error: Embedding file not found: {emb_file}")
        sys.exit(1)
    else:
        print(f"Embedding file found: {emb_file}")

    # Run clustering
    print(f"Running clustering...")
    CLUSTER_ALGO = 'AHC'
    run_command(f"{PYTHON} clustering.py {emb_file} {subseg_file} {rttm_output_dir} {CLUSTER_ALGO}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process audio files for VAD, feature extraction, and clustering.')
    parser.add_argument('audio_path', type=str, help='Path to the audio file')
    parser.add_argument('--output_dir', type=str, help='Optional output directory path')

    args = parser.parse_args()
    main(args.audio_path, args.output_dir)

