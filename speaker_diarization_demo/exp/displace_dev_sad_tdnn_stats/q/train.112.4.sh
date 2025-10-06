#!/bin/bash
cd /data1/prachis/DISPLACE2023/track2_cluster
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  echo -n '# '; cat <<EOF
nnet3-train --use-gpu=yes --read-cache=exp/displace_dev_sad_tdnn_stats/cache.112 --print-interval=10 --momentum=0.5 --max-param-change=0.2 --backstitch-training-scale=0.0 --l2-regularize-factor=0.16666666666666666 --backstitch-training-interval=1 --srand=112 --optimization.min-deriv-time=-34 --optimization.max-deriv-time-relative=56 "nnet3-copy --learning-rate=0.00021640759823113428 --scale=1.0 exp/displace_dev_sad_tdnn_stats/112.raw - |" "ark,bg:nnet3-copy-egs               ark:exp/displace_dev_sad_tdnn_stats/egs/egs.1.ark ark:- |             nnet3-shuffle-egs --buffer-size=5000             --srand=112 ark:- ark:- |              nnet3-merge-egs --minibatch-size=128,64 ark:- ark:- |" exp/displace_dev_sad_tdnn_stats/113.4.raw 
EOF
) >exp/displace_dev_sad_tdnn_stats/log/train.112.4.log
time1=`date +"%s"`
 ( nnet3-train --use-gpu=yes --read-cache=exp/displace_dev_sad_tdnn_stats/cache.112 --print-interval=10 --momentum=0.5 --max-param-change=0.2 --backstitch-training-scale=0.0 --l2-regularize-factor=0.16666666666666666 --backstitch-training-interval=1 --srand=112 --optimization.min-deriv-time=-34 --optimization.max-deriv-time-relative=56 "nnet3-copy --learning-rate=0.00021640759823113428 --scale=1.0 exp/displace_dev_sad_tdnn_stats/112.raw - |" "ark,bg:nnet3-copy-egs               ark:exp/displace_dev_sad_tdnn_stats/egs/egs.1.ark ark:- |             nnet3-shuffle-egs --buffer-size=5000             --srand=112 ark:- ark:- |              nnet3-merge-egs --minibatch-size=128,64 ark:- ark:- |" exp/displace_dev_sad_tdnn_stats/113.4.raw  ) 2>>exp/displace_dev_sad_tdnn_stats/log/train.112.4.log >>exp/displace_dev_sad_tdnn_stats/log/train.112.4.log
ret=$?
time2=`date +"%s"`
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>exp/displace_dev_sad_tdnn_stats/log/train.112.4.log
echo '#' Finished at `date` with status $ret >>exp/displace_dev_sad_tdnn_stats/log/train.112.4.log
[ $ret -eq 137 ] && exit 100;
touch exp/displace_dev_sad_tdnn_stats/q/sync/done.111446
exit $[$ret ? 1 : 0]
## submitted with:
# qsub -v PATH -cwd -S /bin/bash -j y -l arch=*64* -o exp/displace_dev_sad_tdnn_stats/q/train.112.4.log -q gpu.q,longgpu.q -l hostname=compute-0-[0-7] -l gpu=1 -q *.q   /data1/prachis/DISPLACE2023/track2_cluster/exp/displace_dev_sad_tdnn_stats/q/train.112.4.sh >>exp/displace_dev_sad_tdnn_stats/q/train.112.4.log 2>&1
