#!/usr/bin/env bash

set -e -u -o pipefail


################################################################################
# Configuration
################################################################################
# Stage to start from IN THE SCRIPT.
stage=0

# Number of parallel jobs to use during extraction/scoring/clustering.
nj=40

# Proportion of energy to retain when performing the conversation-dependent
# PCA projection. Usual default in Kaldi diarization recipes is 10%, but we use
# 30%, which was found to give better performance by Diez et al. (2020).
#
#   Diez, M. et. al. (2020). "Optimizing Bayesian HMM based x-vector clustering
#   for the Second DIHARD Speech Diarization Challenge." Proceedings of
#   ICASSP 2020.
target_energy=0.3

# AHC threshold.
thresh=-0.2

# If true, ignore "thresh" and instead tune the AHC threshold using the
# reference RTTM. The tuning stage repeats clustering for a range of thresholds
# and selects the one that  yields the lowest DER. Requires that the data
# directory contains a file named "rttm" with the reference diarization. If this
# file is absent, tuning will be skipped and the threshold will default to
# "thresh".
tune=false

period=0.25

# clustering strategy
clustering=spectral

# specific to Spectral clustering
scoretype=None
################################################################################
# Parse options, etc.
################################################################################
if [ -f path.sh ]; then
    . ./path.sh;
fi
if [ -f cmd.sh ]; then
    . ./cmd.sh;
fi
. utils/parse_options.sh || exit 1;
echo $#
if [ $# != 4 ]; then
  echo "usage: $0 <model-dir> <plda-path> <data-dir> <out-dir>"
  echo "e.g.: $0 exp/xvector_nnet_1a exp/xvector_nnet_1a/plda data/dev exp/diarization_nnet_1a_dev"
  echo "  --nj <n|40>         # number of jobs"
  echo "  --stage <stage|0>   # current stage; controls partial reruns"
  echo "  --thresh <t|-0.2>   # AHC threshold"
  echo "  --tune              # tune AHC threshold; data directory must contain reference RTTM"
  exit 1;
fi

# Directory containing the trained x-vector extractor.
model_dir=$1

# Path to the PLDA model to use in scoring.
plda_path=$2

# Data directory containing data to be diarized. If performing AHC tuning (i.e.,
# "--tune true"), must contain a file named "rttm" containing reference
# diarization.
data_dir=$3

# Output directory for x-vectors and diarization.
out_dir=$4

##############################################################################i
# Extract 40-D MFCCs
###############################################################################
name=$(basename $data_dir)
if [ $stage -le 0 ]; then
  echo "$0: Extracting MFCCs...."
  set +e # We expect failures for short segments.
  steps/make_fbank.sh \
    --nj $nj --cmd "$decode_cmd" --write-utt2num-frames true  \
    --fbank-config conf/fbank_16k.conf \
    $data_dir  exp/make_fbank/$name exp/make_fbank/$name
  set -e
fi


###############################################################################
# Prepare feats for x-vector extractor by performing sliding window CMN.
###############################################################################
if [ $stage -le 1 ]; then
  echo "$0: Preparing features for x-vector extractor..."
  local/nnet3/xvector/prepare_feats.sh \
    --nj $nj --cmd "$decode_cmd" \
    data/$name data/${name}_cmn exp/make_fbank/${name}_cmn/
  if [ -f data/$name/vad.scp ]; then
    echo "$0: vad.scp found; copying it"
    cp data/$name/vad.scp data/${name}_cmn/
  fi
  if [ -f data/$name/segments ]; then
    echo "$0: segments found; copying it"
    cp data/$name/segments data/${name}_cmn/
  fi
  utils/fix_data_dir.sh data/${name}_cmn
fi


###############################################################################
# Extract sliding-window x-vectors for all segments.
###############################################################################
xvec_dir=$out_dir/xvectors_$period
if [ $stage -le 2 ]; then
  
  echo "Extracting subsegments ..."
  cmn_dir=data/${name}_cmn
  with_gpu=false
  min_segment=0.25

  local/diarization/nnet3/xvector/form_subsegments.sh \
  --cmd "$decode_cmd" --nj $nj \
  --window 1.5 --period $period --apply-cmn false \
  --min_segment $min_segment \
  $model_dir \
  $cmn_dir $xvec_dir
  cp $xvec_dir/subsegments_data/{segments,spk2utt,utt2spk} $xvec_dir/


fi

if [ $stage -le 3 ]; then
   echo "creating sublists"

    dataset2=$name
   
    mkdir -p $out_dir/lists
    awk '{print $1}' $xvec_dir/spk2utt > $out_dir/lists/${dataset2}.list
    cp $out_dir/lists/$dataset2.list $out_dir/lists/dataset.list
    # store segments filewise in folder segments_xvec
    mkdir -p $xvec_dir/segments_xvec
   
    cat $out_dir/lists/${dataset2}.list | while read i; do
        grep $i $xvec_dir/segments > $xvec_dir/segments_xvec/${i}.segments
    done   
    
    totalfiles=`cat $out_dir/lists/${dataset2}.list | wc -l`
    
    filelen=`expr $totalfiles`
    rm -f $out_dir/lists/full.list

    for i in `seq 1 $filelen`; do
        echo `expr $i - 1` >>  $out_dir/lists/full.list
    done
    python services/split_list.py $out_dir/lists/ $totalfiles $nj

    # check if rttm exists
    if [ -f data/$name/rttm ]; then
      mkdir -p data/$name/filewise_rtttms
      cat $out_dir/lists/${dataset2}.list | while read i; do
          grep $i data/$name/rttm > data/$name/filewise_rtttms/${i}.rttm
      done
    fi

fi

if [ $stage -le 4 ]; then
  echo "$0: Extracting x-vectors, scoring, clustering ..."
  mkdir -p $xvec_dir/xvectors_npy

  local/diarization/diarization_python.sh \
    --nj $nj --cmd "$decode_cmd" \
    --reco2utt_list $xvec_dir/spk2utt \
    --segments_list $xvec_dir/segments_xvec \
    --splitname $out_dir/lists/split$nj \
    --target_energy $target_energy \
    --threshold $thresh \
     $xvec_dir/subsegments_data/feats.scp  $xvec_dir/xvectors_npy \
     $out_dir



fi


###############################################################################
# Determine clustering threshold.
###############################################################################
if [ $stage -le 5 ]; then
  tuning_dir=$out_dir/tuning_$period
  if [ -z $data_dir/dataset.list ]; then
    awk '{print $1}' $data_dir/wav.scp >  $data_dir/dataset.list
  fi
  mkdir -p $tuning_dir
  ref_rttm=$data_dir/rttm
  echo "$0: Determining Spectral threshold..."
  if [[ $tune == true ]] && [[ -f $ref_rttm ]]; then
    echo "$0: Tuning threshold using reference diarization stored in: ${ref_rttm}"
    best_der=1000
    best_thresh=0
    # 0.1 0.2 0.3 0.4 0.1 0.2 0.3 0.4 0.5 0.6
    for thresh in 0.1 0.2 0.3 0.4 0.5 0.6 0.7 ; do
      echo "$0: Clustering with spectral threshold ${thresh}..."
      cluster_dir=$tuning_dir/plda_scores_t${thresh}
      mkdir -p $cluster_dir
      local/diarization/my_spectral_cluster.sh \
        --nj $nj --cmd "$decode_cmd" \
  --threshold $thresh --rttm-channel 1 --score_path $plda_dir \
  --score_file $data_dir/dataset.list \
  --scoretype $scoretype \
  $plda_dir $cluster_dir
      perl local/diarization/md-eval.pl \
        -r $ref_rttm -s $cluster_dir/rttm \
        > $tuning_dir/der_t${thresh} \
  2> $tuning_dir/der_t${thresh}.log
      der=$(grep -oP 'DIARIZATION\ ERROR\ =\ \K[0-9]+([.][0-9]+)?' \
        $tuning_dir/der_t${thresh})
      if [ $(echo $der'<'$best_der | bc -l) -eq 1 ]; then
          best_der=$der
          best_thresh=$thresh
      fi
    done
    echo "$best_thresh" > $tuning_dir/thresh_best
    echo "$0: ***** Results of tuning *****"
    echo "$0: *** Best threshold is: $best_thresh"
    echo "$0: *** DER using this threshold: $best_der"
  else
    echo "$thresh" > $tuning_dir/thresh_best
  fi
fi


###############################################################################
# Cluster using selected threshold
###############################################################################
if [ $stage -le 6 ]; then
  tuning_dir=$out_dir/tuning_$period
  if [ -z $data_dir/dataset.list ]; then
    awk '{print $1}' $data_dir/wav.scp >  $data_dir/dataset.list
  fi
  # best_thresh=$(cat $tuning_dir/thresh_best)
  best_thresh=$thresh
  echo "$0: Performing Spectral using threshold ${best_thresh}..."
  local/diarization/my_spectral_cluster.sh \
    --nj $nj --cmd "$decode_cmd" \
    --threshold $best_thresh --rttm-channel 1 --score_path $plda_dir \
    --score_file $data_dir/dataset.list \
    --scoretype $scoretype \
    $plda_dir $out_dir
  local/diarization/split_rttm.py \
    $out_dir/rttm $out_dir/per_file_rttm
fi
