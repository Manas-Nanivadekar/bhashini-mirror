#!/bin/bash
cd /data1/prachis/DISPLACE2023/track2_cluster
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  echo -n '# '; cat <<EOF
nnet3-compute-prob --compute-per-dim-accuracy exp/displace_dev_sad_tdnn_stats/86.raw "ark,bg:nnet3-copy-egs                      ark:exp/displace_dev_sad_tdnn_stats/egs/train_diagnostic.egs ark:- |                     nnet3-merge-egs --minibatch-size=1:64 ark:-                     ark:- |" 
EOF
) >exp/displace_dev_sad_tdnn_stats/log/compute_prob_train.86.log
time1=`date +"%s"`
 ( nnet3-compute-prob --compute-per-dim-accuracy exp/displace_dev_sad_tdnn_stats/86.raw "ark,bg:nnet3-copy-egs                      ark:exp/displace_dev_sad_tdnn_stats/egs/train_diagnostic.egs ark:- |                     nnet3-merge-egs --minibatch-size=1:64 ark:-                     ark:- |"  ) 2>>exp/displace_dev_sad_tdnn_stats/log/compute_prob_train.86.log >>exp/displace_dev_sad_tdnn_stats/log/compute_prob_train.86.log
ret=$?
time2=`date +"%s"`
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>exp/displace_dev_sad_tdnn_stats/log/compute_prob_train.86.log
echo '#' Finished at `date` with status $ret >>exp/displace_dev_sad_tdnn_stats/log/compute_prob_train.86.log
[ $ret -eq 137 ] && exit 100;
touch exp/displace_dev_sad_tdnn_stats/q/sync/done.102053
exit $[$ret ? 1 : 0]
## submitted with:
# qsub -v PATH -cwd -S /bin/bash -j y -l arch=*64* -o exp/displace_dev_sad_tdnn_stats/q/compute_prob_train.86.log -q gpu.q,longgpu.q -l hostname=compute-0-[0-7]    /data1/prachis/DISPLACE2023/track2_cluster/exp/displace_dev_sad_tdnn_stats/q/compute_prob_train.86.sh >>exp/displace_dev_sad_tdnn_stats/q/compute_prob_train.86.log 2>&1
