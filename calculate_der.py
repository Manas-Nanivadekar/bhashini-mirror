#!/usr/bin/env python3

import sys
from pyannote.core import Annotation, Segment
from pyannote.metrics.diarization import DiarizationErrorRate

def load_rttm(rttm_file):
    """Load RTTM file into pyannote Annotation"""
    annotation = Annotation()
    
    with open(rttm_file, 'r') as f:
        for line in f:
            if line.startswith('SPEAKER'):
                parts = line.strip().split()
                recording_id = parts[1]
                start = float(parts[3])
                duration = float(parts[4])
                speaker = parts[7]
                
                segment = Segment(start, start + duration)
                annotation[segment] = speaker
    
    return annotation

def calculate_der(reference_rttm, hypothesis_rttm):
    """Calculate DER between reference and hypothesis"""
    reference = load_rttm(reference_rttm)
    hypothesis = load_rttm(hypothesis_rttm)
    
    metric = DiarizationErrorRate()
    der = metric(reference, hypothesis)
    
    # Get detailed components
    components = metric.compute_components(reference, hypothesis)
    
    print(f"\n{'='*60}")
    print(f"Diarization Error Rate (DER) Analysis")
    print(f"{'='*60}")
    print(f"\nReference: {reference_rttm}")
    print(f"Hypothesis: {hypothesis_rttm}")
    print(f"\n{'='*60}")
    print(f"Overall DER: {der:.2%}")
    print(f"{'='*60}")
    
    if components:
        print(f"\nDetailed Breakdown:")
        print(f"  False Alarm:     {components['false alarm']:.2%}")
        print(f"  Missed Detection: {components['missed detection']:.2%}")
        print(f"  Confusion:       {components['confusion']:.2%}")
    
    print(f"\n{'='*60}\n")
    
    return der

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python calculate_der.py <reference.rttm> <hypothesis.rttm>")
        sys.exit(1)
    
    reference_rttm = sys.argv[1]
    hypothesis_rttm = sys.argv[2]
    
    der = calculate_der(reference_rttm, hypothesis_rttm)
