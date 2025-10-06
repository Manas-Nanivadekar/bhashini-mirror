#!/bin/bash
cd /data1/prachis/DISPLACE2023/track2_cluster
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  echo -n '# '; cat <<EOF
nnet3-compute-prob exp/displace_dev_sad_tdnn_stats/13.raw "ark,bg:nnet3-copy-egs                      ark:exp/displace_dev_sad_tdnn_stats/egs/valid_diagnostic.egs ark:- |                     nnet3-merge-egs --minibatch-size=1:64 ark:-                     ark:- |" 
EOF
) >exp/displace_dev_sad_tdnn_stats/log/compute_prob_valid.13.log
time1=`date +"%s"`
 ( nnet3-compute-prob exp/displace_dev_sad_tdnn_stats/13.raw "ark,bg:nnet3-copy-egs                      ark:exp/displace_dev_sad_tdnn_stats/egs/valid_diagnostic.egs ark:- |                     nnet3-merge-egs --minibatch-size=1:64 ark:-                     ark:- |"  ) 2>>exp/displace_dev_sad_tdnn_stats/log/compute_prob_valid.13.log >>exp/displace_dev_sad_tdnn_stats/log/compute_prob_valid.13.log
ret=$?
time2=`date +"%s"`
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>exp/displace_dev_sad_tdnn_stats/log/compute_prob_valid.13.log
echo '#' Finished at `date` with status $ret >>exp/displace_dev_sad_tdnn_stats/log/compute_prob_valid.13.log
[ $ret -eq 137 ] && exit 100;
touch exp/displace_dev_sad_tdnn_stats/q/sync/done.77602
exit $[$ret ? 1 : 0]
## submitted with:
# qsub -v PATH -cwd -S /bin/bash -j y -l arch=*64* -o exp/displace_dev_sad_tdnn_stats/q/compute_prob_valid.13.log -q gpu.q,longgpu.q -l hostname=compute-0-[0-7]    /data1/prachis/DISPLACE2023/track2_cluster/exp/displace_dev_sad_tdnn_stats/q/compute_prob_valid.13.sh >>exp/displace_dev_sad_tdnn_stats/q/compute_prob_valid.13.log 2>&1
