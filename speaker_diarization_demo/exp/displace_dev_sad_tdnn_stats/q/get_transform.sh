#!/bin/bash
cd /data1/prachis/DISPLACE2023/track2_cluster
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  echo -n '# '; cat <<EOF
nnet-get-feature-transform exp/displace_dev_sad_tdnn_stats/lda.mat exp/displace_dev_sad_tdnn_stats/lda_stats 
EOF
) >exp/displace_dev_sad_tdnn_stats/log/get_transform.log
time1=`date +"%s"`
 ( nnet-get-feature-transform exp/displace_dev_sad_tdnn_stats/lda.mat exp/displace_dev_sad_tdnn_stats/lda_stats  ) 2>>exp/displace_dev_sad_tdnn_stats/log/get_transform.log >>exp/displace_dev_sad_tdnn_stats/log/get_transform.log
ret=$?
time2=`date +"%s"`
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>exp/displace_dev_sad_tdnn_stats/log/get_transform.log
echo '#' Finished at `date` with status $ret >>exp/displace_dev_sad_tdnn_stats/log/get_transform.log
[ $ret -eq 137 ] && exit 100;
touch exp/displace_dev_sad_tdnn_stats/q/sync/done.36913
exit $[$ret ? 1 : 0]
## submitted with:
# qsub -v PATH -cwd -S /bin/bash -j y -l arch=*64* -o exp/displace_dev_sad_tdnn_stats/q/get_transform.log    /data1/prachis/DISPLACE2023/track2_cluster/exp/displace_dev_sad_tdnn_stats/q/get_transform.sh >>exp/displace_dev_sad_tdnn_stats/q/get_transform.log 2>&1
