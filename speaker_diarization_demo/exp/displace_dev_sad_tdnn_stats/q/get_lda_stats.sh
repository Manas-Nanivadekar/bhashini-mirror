#!/bin/bash
cd /data1/prachis/DISPLACE2023/track2_cluster
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  echo -n '# '; cat <<EOF
nnet3-acc-lda-stats --rand-prune=4.0 exp/displace_dev_sad_tdnn_stats/init.raw "ark:nnet3-copy-egs  ark:exp/displace_dev_sad_tdnn_stats/egs/egs.${SGE_TASK_ID}.ark ark:- |" exp/displace_dev_sad_tdnn_stats/${SGE_TASK_ID}.lda_stats 
EOF
) >exp/displace_dev_sad_tdnn_stats/log/get_lda_stats.$SGE_TASK_ID.log
time1=`date +"%s"`
 ( nnet3-acc-lda-stats --rand-prune=4.0 exp/displace_dev_sad_tdnn_stats/init.raw "ark:nnet3-copy-egs  ark:exp/displace_dev_sad_tdnn_stats/egs/egs.${SGE_TASK_ID}.ark ark:- |" exp/displace_dev_sad_tdnn_stats/${SGE_TASK_ID}.lda_stats  ) 2>>exp/displace_dev_sad_tdnn_stats/log/get_lda_stats.$SGE_TASK_ID.log >>exp/displace_dev_sad_tdnn_stats/log/get_lda_stats.$SGE_TASK_ID.log
ret=$?
time2=`date +"%s"`
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>exp/displace_dev_sad_tdnn_stats/log/get_lda_stats.$SGE_TASK_ID.log
echo '#' Finished at `date` with status $ret >>exp/displace_dev_sad_tdnn_stats/log/get_lda_stats.$SGE_TASK_ID.log
[ $ret -eq 137 ] && exit 100;
touch exp/displace_dev_sad_tdnn_stats/q/sync/done.34341.$SGE_TASK_ID
exit $[$ret ? 1 : 0]
## submitted with:
# qsub -v PATH -cwd -S /bin/bash -j y -l arch=*64* -o exp/displace_dev_sad_tdnn_stats/q/get_lda_stats.log   -t 1:10 /data1/prachis/DISPLACE2023/track2_cluster/exp/displace_dev_sad_tdnn_stats/q/get_lda_stats.sh >>exp/displace_dev_sad_tdnn_stats/q/get_lda_stats.log 2>&1
