#!/bin/bash
cd /data1/prachis/DISPLACE2023/track2_cluster
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  echo -n '# '; cat <<EOF
nnet3-average exp/displace_dev_sad_tdnn_stats/84.1.raw exp/displace_dev_sad_tdnn_stats/84.2.raw exp/displace_dev_sad_tdnn_stats/84.3.raw exp/displace_dev_sad_tdnn_stats/84.4.raw exp/displace_dev_sad_tdnn_stats/84.5.raw exp/displace_dev_sad_tdnn_stats/84.raw 
EOF
) >exp/displace_dev_sad_tdnn_stats/log/average.83.log
time1=`date +"%s"`
 ( nnet3-average exp/displace_dev_sad_tdnn_stats/84.1.raw exp/displace_dev_sad_tdnn_stats/84.2.raw exp/displace_dev_sad_tdnn_stats/84.3.raw exp/displace_dev_sad_tdnn_stats/84.4.raw exp/displace_dev_sad_tdnn_stats/84.5.raw exp/displace_dev_sad_tdnn_stats/84.raw  ) 2>>exp/displace_dev_sad_tdnn_stats/log/average.83.log >>exp/displace_dev_sad_tdnn_stats/log/average.83.log
ret=$?
time2=`date +"%s"`
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>exp/displace_dev_sad_tdnn_stats/log/average.83.log
echo '#' Finished at `date` with status $ret >>exp/displace_dev_sad_tdnn_stats/log/average.83.log
[ $ret -eq 137 ] && exit 100;
touch exp/displace_dev_sad_tdnn_stats/q/sync/done.101365
exit $[$ret ? 1 : 0]
## submitted with:
# qsub -v PATH -cwd -S /bin/bash -j y -l arch=*64* -o exp/displace_dev_sad_tdnn_stats/q/average.83.log -q gpu.q,longgpu.q -l hostname=compute-0-[0-7]    /data1/prachis/DISPLACE2023/track2_cluster/exp/displace_dev_sad_tdnn_stats/q/average.83.sh >>exp/displace_dev_sad_tdnn_stats/q/average.83.log 2>&1
