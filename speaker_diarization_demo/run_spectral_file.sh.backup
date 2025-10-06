#!/bin/bash
# this code is to generate diarization results for DISPLACE full DEV and EVAL part 1 
set -e  # Exit on error.

PYTHON=python  # Python to use; defaults to system Python.


################################################################################
# Configuration
################################################################################
nj=1 # increase this based on the number of processors available
decode_nj=1
stage=0
sad_train_stage=0
sad_decode_stage=0
diarization_stage=0
vb_hmm_stage=0
overlap=0
# If following is "true", then SAD output will be evaluated against reference
# following decoding stage. This step requires the following Python packages be
# installed:
#
# - pyannote.core
# - pyannote.metrics
# - pandas
eval_sad=false

# /home/shikhab/Codes/Speaker_diarization/DISPLACE2023_Prachi/data/After_tier1_tier2_and_overlap_corrections_300ms_gapMerged/Dev

wav_file=$1 #/data1/apoorvak/SD_SID_combined/Updated_demo/input/Lok_Sabha_Zero_Hour_1204_PM_-_0130_PM_07_December_2023_12min.wav #/path/to/wav_file
dataset=$2
rttm_file= #optional
thresh=0.6 #for clustering 
pyannote_pretrained_model=vad_benchmarking/VAD_model/pytorch_model.bin # SAD and Overlap pyannote model.

. ./utils/parse_options.sh

if [ $wav_file = "default" ];then
  echo "provide wav file to proceed"

  echo "usage"
  echo "run_spectral_file.sh --wav_file <wav_file> --dataset <output data folder name>"
  exit 0
fi
. ./cmd.sh
. ./path.sh


startfull=`date +%s`
################################################################################
# Prepare data directories
################################################################################
if [ $stage -le 0 ]; then
  echo "$0: Preparing data directories..."

  # eval
  if [ -f "$wav_file" ]; then 
  # local/make_data_dir_file.py \
  #   data/displace_eval_fbank \
  #   $DISPLACE_EVAL_DIR/data/wav 

   ./create_data_dir.sh data/$dataset $wav_file
  ./utils/validate_data_dir.sh \
    --no-text --no-feats data/$dataset/
  else
    echo "${wav_file} does not exist"
  fi
fi

start=`date +%s`
#####################################
# SAD decoding.
#####################################
if [ $stage -le 1 ]; then
  echo "$0: Applying SAD model to DEV/EVAL..."
  [[ -e data/${dataset}_seg ]] && rm -rf data/${dataset}_seg
  # local/segmentation/detect_speech_activity.sh \
  #   --nj $nj --stage $sad_decode_stage \
  #   data/$dataset exp/dihard3_sad_tdnn_stats \
  #   mfcc exp/${dataset}_sad_tdnn_stats_decode \
  #   data/${dataset}_seg

  sad_model=$pyannote_pretrained_model
  # eval
  vad_benchmarking/run_pyannote_SAD.sh \
    --nj $nj --stage $sad_decode_stage \
    data/${dataset} data/${dataset}_seg \
    $sad_model 

fi
end=`date +%s`
echo "#########################################################"
echo SAD Execution time was `expr $end - $start` seconds.
echo "#########################################################"
################################################################################
# Perform first-pass diarization using AHC.
################################################################################
period=0.25
scoretype=laplacian
outevaldir=exp/${dataset}_diarization_fbank_spectral

start=`date +%s`
if [ $stage -le 2 ]; then
  # cp -r exp/displace_diarization_nnet_1a_eval_fbank_spectral $outevaldir
  echo "$0: Performing first-pass diarization of EVAL using threshold "
  echo "$0: obtained by tuning on DEV..."
  # thresh=$(cat ${outdevdir}/tuning_${period}/thresh_best)
  
  local/diarize_fbank.sh \
    --nj $decode_nj --stage $diarization_stage \
    --thresh $thresh --tune false --period $period  --clustering spectral \
    --scoretype $scoretype \
    exp/xvector_nnet_1a_tdnn_fbank/ exp/xvector_nnet_1a_tdnn_fbank/plda_model_full \
    data/${dataset}_seg/ $outevaldir
fi

end=`date +%s`
echo "#########################################################"
echo Speaker Diarization Execution time was `expr $end - $start` seconds.
echo "#########################################################"

################################################################################
# Refined first-pass diarization using VB-HMM resegmentation
################################################################################
dubm_model=exp/xvec_init_gauss_1024_ivec_400/model/diag_ubm.pkl
ie_model=exp/xvec_init_gauss_1024_ivec_400/model/ie.pkl
PYTHON=/home/prachis/.conda/envs/pyannote/bin/python

# outevaldir=exp/displace_diarization_nnet_1a_eval_fbank_spectral
# outevaldir_vb=exp/displace_diarization_nnet_1a_vbhmm_eval_spectral

outevaldir_vb=exp/${dataset}_diarization_vbhmm_spectral

start=`date +%s`

if [ $stage -le 3 ]; then
  echo "$0: Performing VB-HMM resegmentation of EVAL..."
  # local/resegment_vbhmm.sh \
  #     --nj $decode_nj --stage $vb_hmm_stage \
  #     data/${dataset} $outevaldir/rttm \
  #     $dubm_model $ie_model $outevaldir_vb/

  local/resegment_vbhmm.sh \
        --nj $decode_nj --stage $vb_hmm_stage \
        --overlap 1 --PYTHON $PYTHON \
        --pyannote_pretrained_model $pyannote_pretrained_model \
        data/${dataset} $outevaldir/rttm \
        $dubm_model $ie_model $outevaldir_vb/ 
fi

end=`date +%s`
echo "#########################################################"
echo VB-HMM Execution time was `expr $end - $start` seconds.
echo "#########################################################"
echo Total Execution time was `expr $end - $startfull` seconds.
echo "#########################################################"
################################################################################
# Evaluate VB-HMM resegmentation.
################################################################################
if [ $stage -le 4 ] && [ ! -z $rttm_file ]; then
  if [ ! -z $rttm_file ]; then
    echo "$0: Scoring VB-HMM resegmentation on EVAL..."
    local/diarization/score_diarization.sh \
      --scores-dir $outevaldir_vb/scoring \
      $rttm_file $outevaldir_vb/per_file_rttm
  fi
fi
