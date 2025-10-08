#!/usr/bin/env python
"""
Overlap detection using modern pyannote.audio Pipeline API.

Replaces legacy torch.hub access to `ovl_dihard/ovl_ami`.
"""
import argparse
import os
from pathlib import Path
from pyannote.audio import Pipeline


def _load_dotenv_upwards(filename: str = ".env", max_up: int = 5) -> None:
    try:
        here = Path(__file__).resolve().parent
    except Exception:
        here = Path.cwd()
    candidates = [Path.cwd(), here] + list(here.parents)[:max_up]
    for base in candidates:
        env_path = base / filename
        if env_path.is_file():
            for line in env_path.read_text().splitlines():
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip())
            break


def read_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("wav_scp", help="Path to wav.scp file")
    parser.add_argument("out_dir", help="Path to output dir")
    parser.add_argument(
        "--pretrained-id",
        type=str,
        default="pyannote/overlapped-speech-detection",
        help="Hugging Face model id or local path for overlapped speech detection",
    )
    parser.add_argument(
        "--hf-token",
        type=str,
        default=os.environ.get("HF_TOKEN"),
        help="Hugging Face access token (or set HF_TOKEN env)",
    )
    args = parser.parse_args()
    return args


def main(wav_scp, out_dir, pretrained_id, hf_token=None):
    _load_dotenv_upwards()
    hf_token = hf_token or os.environ.get("HF_TOKEN")
    if hf_token:
        pipeline = Pipeline.from_pretrained(pretrained_id, use_auth_token=hf_token)
    else:
        pipeline = Pipeline.from_pretrained(pretrained_id)

    os.makedirs(out_dir, exist_ok=True)
    with open(wav_scp, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) == 2:
                file_id, wav_path = parts
            else:
                # Kaldi-style: <utt> <sox/cmd ... wav>
                file_id, wav_path = parts[0], parts[2]
            diar = pipeline(wav_path)
            with open(os.path.join(out_dir, f"{file_id}.rttm"), 'w') as f_out:
                diar.write_rttm(f_out)


if __name__ == "__main__":
    args = read_args()
    main(args.wav_scp, args.out_dir, pretrained_id=args.pretrained_id, hf_token=args.hf_token)
