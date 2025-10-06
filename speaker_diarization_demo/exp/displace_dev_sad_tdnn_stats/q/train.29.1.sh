#!/bin/bash
cd /data1/prachis/DISPLACE2023/track2_cluster
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  echo -n '# '; cat <<EOF
nnet3-train --use-gpu=yes --read-cache=exp/displace_dev_sad_tdnn_stats/cache.29 --write-cache=exp/displace_dev_sad_tdnn_stats/cache.30 --print-interval=10 --momentum=0.5 --max-param-change=0.2 --backstitch-training-scale=0.0 --l2-regularize-factor=0.25 --backstitch-training-interval=1 --srand=29 --optimization.min-deriv-time=-34 --optimization.max-deriv-time-relative=56 "nnet3-copy --learning-rate=0.0007688611426410646 --scale=1.0 exp/displace_dev_sad_tdnn_stats/29.raw - |" "ark,bg:nnet3-copy-egs               ark:exp/displace_dev_sad_tdnn_stats/egs/egs.12.ark ark:- |             nnet3-shuffle-egs --buffer-size=5000             --srand=29 ark:- ark:- |              nnet3-merge-egs --minibatch-size=128,64 ark:- ark:- |" exp/displace_dev_sad_tdnn_stats/30.1.raw 
EOF
) >exp/displace_dev_sad_tdnn_stats/log/train.29.1.log
time1=`date +"%s"`
 ( nnet3-train --use-gpu=yes --read-cache=exp/displace_dev_sad_tdnn_stats/cache.29 --write-cache=exp/displace_dev_sad_tdnn_stats/cache.30 --print-interval=10 --momentum=0.5 --max-param-change=0.2 --backstitch-training-scale=0.0 --l2-regularize-factor=0.25 --backstitch-training-interval=1 --srand=29 --optimization.min-deriv-time=-34 --optimization.max-deriv-time-relative=56 "nnet3-copy --learning-rate=0.0007688611426410646 --scale=1.0 exp/displace_dev_sad_tdnn_stats/29.raw - |" "ark,bg:nnet3-copy-egs               ark:exp/displace_dev_sad_tdnn_stats/egs/egs.12.ark ark:- |             nnet3-shuffle-egs --buffer-size=5000             --srand=29 ark:- ark:- |              nnet3-merge-egs --minibatch-size=128,64 ark:- ark:- |" exp/displace_dev_sad_tdnn_stats/30.1.raw  ) 2>>exp/displace_dev_sad_tdnn_stats/log/train.29.1.log >>exp/displace_dev_sad_tdnn_stats/log/train.29.1.log
ret=$?
time2=`date +"%s"`
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>exp/displace_dev_sad_tdnn_stats/log/train.29.1.log
echo '#' Finished at `date` with status $ret >>exp/displace_dev_sad_tdnn_stats/log/train.29.1.log
[ $ret -eq 137 ] && exit 100;
touch exp/displace_dev_sad_tdnn_stats/q/sync/done.84782
exit $[$ret ? 1 : 0]
## submitted with:
# qsub -v PATH -cwd -S /bin/bash -j y -l arch=*64* -o exp/displace_dev_sad_tdnn_stats/q/train.29.1.log -q gpu.q,longgpu.q -l hostname=compute-0-[0-7] -l gpu=1 -q *.q   /data1/prachis/DISPLACE2023/track2_cluster/exp/displace_dev_sad_tdnn_stats/q/train.29.1.sh >>exp/displace_dev_sad_tdnn_stats/q/train.29.1.log 2>&1
