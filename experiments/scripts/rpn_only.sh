#!/bin/bash
# Usage:
# ./experiments/scripts/faster_rcnn_rpn_only.sh GPU NET DATASET [options args to {train,test}_net.py]
# DATASET is only pascal_voc for now
#
# Example:
# ./experiments/scripts/faster_rcnn_rpn_only.sh 0 VGG_CNN_M_1024 pascal_voc --iters ${ITERS} \\
#   --set EXP_DIR foobar RNG_SEED 42 TRAIN.SCALES "[400, 500, 600, 700]"

# Train rpn only

set -x
set -e

export PYTHONUNBUFFERED="True"

GPU_ID=$1
NET=$2
NET_lc=${NET,,}
DATASET=$3

array=( $@ )
len=${#array[@]}
EXTRA_ARGS=${array[@]:3:$len}
EXTRA_ARGS_SLUG=${EXTRA_ARGS// /_}

case $DATASET in
  caltech_voc)
    TRAIN_IMDB="voc_2007_trainval"
    TEST_IMDB="voc_2007_test"
    PT_DIR="caltech"
    ;;
  coco)
    echo "Not implemented: use experiments/scripts/faster_rcnn_end2end.sh for coco"
    exit
    ;;
  *)
    echo "No dataset given"
    exit
    ;;
esac

LOG="experiments/logs/rpn_only_${NET}_${EXTRA_ARGS_SLUG}.txt.`date +'%Y-%m-%d_%H-%M-%S'`"
exec &> >(tee -a "$LOG")
echo Logging output to "$LOG"

time ./tools/train_faster_rcnn_rpn_only.py --gpu ${GPU_ID} \
  --net_name ${NET} \
  --weights data/imagenet_models/${NET}.v2.caffemodel \
  --imdb ${TRAIN_IMDB} \
  --cfg experiments/cfgs/faster_rcnn_rpn_only.yml \
  --test_imdb ${TEST_IMDB} \
  ${EXTRA_ARGS}

set +x
RPN_FILE=`grep "Wrote RPN proposals" ${LOG} | awk '{print $5}'`
set -x

METHOD="rpn"

time ./tools/eval_recall.py --imdb ${TEST_IMDB} --method ${METHOD} --rpn-file ${RPN_FILE}
