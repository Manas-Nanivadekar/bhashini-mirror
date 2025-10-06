#!/bin/bash
path=$1
inputfile=$2

mkdir -p $path
if [ ! -f $path/wav.scp ]; then
s=${inputfile##*/}
filename=${s%.*}
echo $filename
echo "$filename sox $2 -t wav -b 16 - rate 16000 remix 1 |" > $path/wav.scp
#echo "$filename $2" > $path/wav.scp
fi

if [ ! -f $path/utt2spk ]; then
 awk '{print $1,$1}' $path/wav.scp > $path/utt2spk
fi
 utils/utt2spk_to_spk2utt.pl \
    $path/utt2spk > $path/spk2utt

# source=$path/rttm 
# target=$2/data/final.rttm
# cp $source $target 
