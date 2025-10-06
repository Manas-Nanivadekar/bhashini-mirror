#bin/bash

cmd="run.pl"

xvecmodelpath=torch_models/fbank_jhu_etdnn.pkl
pldamodel=torch_models/plda_displace_dev_fbank_0.75s.pkl

dataset=displace_dev_fbank
segments_list=lists//${dataset}/segments_xvec
reco2utt_list=lists/${dataset}/tmp/spk2utt
threshold=
target_energy=
splitname=
nj=1
echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

featspath=$1
xvecpath_out=$2
outpath=$3
filelist=$3/lists/dataset.list
JOB=1
# $cmd JOB=1:$nj $outpath/log/extract_xvectors.JOB.log \
python local/diarization/diarization_torch.py \
--featspath ${featspath} \
--feats_file $filelist \
--reco2utt_list $reco2utt_list \
--segments_list $segments_list \
--splitlist $splitname/$JOB/full.list \
--xvec_model_weight_path $xvecmodelpath \
--xvecpath_out $xvecpath_out \
--pldamodel $pldamodel  \
--out_path $outpath \
--threshold $threshold

cat $outpath/per_file_rttm/*.rttm > $outpath/rttm