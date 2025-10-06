#!/bin/bash
cd /data1/prachis/DISPLACE2023/track2_cluster
. ./path.sh
( echo '#' Running on `hostname`
  echo '#' Started at `date`
  echo -n '# '; cat <<EOF
nnet3-init --srand=-2 exp/displace_dev_sad_tdnn_stats/configs/init.config exp/displace_dev_sad_tdnn_stats/init.raw 
EOF
) >exp/displace_dev_sad_tdnn_stats/log/nnet_init.log
time1=`date +"%s"`
 ( nnet3-init --srand=-2 exp/displace_dev_sad_tdnn_stats/configs/init.config exp/displace_dev_sad_tdnn_stats/init.raw  ) 2>>exp/displace_dev_sad_tdnn_stats/log/nnet_init.log >>exp/displace_dev_sad_tdnn_stats/log/nnet_init.log
ret=$?
time2=`date +"%s"`
echo '#' Accounting: time=$(($time2-$time1)) threads=1 >>exp/displace_dev_sad_tdnn_stats/log/nnet_init.log
echo '#' Finished at `date` with status $ret >>exp/displace_dev_sad_tdnn_stats/log/nnet_init.log
[ $ret -eq 137 ] && exit 100;
touch exp/displace_dev_sad_tdnn_stats/q/sync/done.69341
exit $[$ret ? 1 : 0]
## submitted with:
# qsub -v PATH -cwd -S /bin/bash -j y -l arch=*64* -o exp/displace_dev_sad_tdnn_stats/q/nnet_init.log    /data1/prachis/DISPLACE2023/track2_cluster/exp/displace_dev_sad_tdnn_stats/q/nnet_init.sh >>exp/displace_dev_sad_tdnn_stats/q/nnet_init.log 2>&1
