import re
import sys
import os
import argparse
from pyannote.audio.pipelines import VoiceActivityDetection
from pyannote.audio import Model

def pyannote_model_instance():
    model = Model.from_pretrained("pyannote/segmentation-3.0", use_auth_token="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")
    HYPER_PARAMETERS = {
        "min_duration_on": 0.0,
        "min_duration_off": 0.0}
    pipeline = VoiceActivityDetection(segmentation=model)
    pipeline.instantiate(HYPER_PARAMETERS)
    return pipeline

def to_kaldi(vad, input_file_name, output_path):
    segments = vad.split("\n")
    segments = list(filter(lambda x: x != "", segments))
    with open(output_path, 'w') as f:
        prev_end_time = 0
        for i in range(len(segments)):
            start_time, end_time = segments[i].strip().split()
            if float(start_time) >= prev_end_time:
                start_time_pt = str("%.3f" % float(start_time))
                end_time_pt = str("%.3f" % float(end_time))
                utt_id_suffix = "0" * (7 - len(start_time_pt.replace(".", ""))) + start_time_pt.replace(".", "") + "-" + "0" * (7 - len(end_time_pt.replace(".", ""))) + end_time_pt.replace(".", "")
                utt_id = f"{input_file_name}-{utt_id_suffix}"
                f.write(f"{utt_id} {input_file_name} {start_time_pt} {end_time_pt}\n")
                prev_end_time = float(end_time)

def compute_vad(input_wav, output_dir):
    pipeline = pyannote_model_instance()
    vad = pipeline(input_wav).to_lab()
    vad = re.sub(" SPEECH", '', vad)
    f_name = os.path.basename(input_wav).split(".wav")[0]
    
    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    output_path = os.path.join(output_dir, f"{f_name}_pyannote_segment.txt")
    to_kaldi(vad, f_name, output_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run VAD on an audio file and save the output.")
    parser.add_argument("audio_path", type=str, help="Path to the audio file")
    parser.add_argument("output_dir", type=str, help="Directory to save the VAD output file")

    args = parser.parse_args()
    compute_vad(args.audio_path, args.output_dir)

