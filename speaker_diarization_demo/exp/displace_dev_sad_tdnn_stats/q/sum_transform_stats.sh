#!/bin/bash
cd /data1/prachis/DISPLACE2023/track2_cluster
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  echo -n '# '; cat <<EOF
sum-lda-accs exp/displace_dev_sad_tdnn_stats/lda_stats exp/displace_dev_sad_tdnn_stats/1.lda_stats exp/displace_dev_sad_tdnn_stats/2.lda_stats exp/displace_dev_sad_tdnn_stats/3.lda_stats exp/displace_dev_sad_tdnn_stats/4.lda_stats exp/displace_dev_sad_tdnn_stats/5.lda_stats exp/displace_dev_sad_tdnn_stats/6.lda_stats exp/displace_dev_sad_tdnn_stats/7.lda_stats exp/displace_dev_sad_tdnn_stats/8.lda_stats exp/displace_dev_sad_tdnn_stats/9.lda_stats exp/displace_dev_sad_tdnn_stats/10.lda_stats 
EOF
) >exp/displace_dev_sad_tdnn_stats/log/sum_transform_stats.log
time1=`date +"%s"`
 ( sum-lda-accs exp/displace_dev_sad_tdnn_stats/lda_stats exp/displace_dev_sad_tdnn_stats/1.lda_stats exp/displace_dev_sad_tdnn_stats/2.lda_stats exp/displace_dev_sad_tdnn_stats/3.lda_stats exp/displace_dev_sad_tdnn_stats/4.lda_stats exp/displace_dev_sad_tdnn_stats/5.lda_stats exp/displace_dev_sad_tdnn_stats/6.lda_stats exp/displace_dev_sad_tdnn_stats/7.lda_stats exp/displace_dev_sad_tdnn_stats/8.lda_stats exp/displace_dev_sad_tdnn_stats/9.lda_stats exp/displace_dev_sad_tdnn_stats/10.lda_stats  ) 2>>exp/displace_dev_sad_tdnn_stats/log/sum_transform_stats.log >>exp/displace_dev_sad_tdnn_stats/log/sum_transform_stats.log
ret=$?
time2=`date +"%s"`
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>exp/displace_dev_sad_tdnn_stats/log/sum_transform_stats.log
echo '#' Finished at `date` with status $ret >>exp/displace_dev_sad_tdnn_stats/log/sum_transform_stats.log
[ $ret -eq 137 ] && exit 100;
touch exp/displace_dev_sad_tdnn_stats/q/sync/done.35296
exit $[$ret ? 1 : 0]
## submitted with:
# qsub -v PATH -cwd -S /bin/bash -j y -l arch=*64* -o exp/displace_dev_sad_tdnn_stats/q/sum_transform_stats.log    /data1/prachis/DISPLACE2023/track2_cluster/exp/displace_dev_sad_tdnn_stats/q/sum_transform_stats.sh >>exp/displace_dev_sad_tdnn_stats/q/sum_transform_stats.log 2>&1
