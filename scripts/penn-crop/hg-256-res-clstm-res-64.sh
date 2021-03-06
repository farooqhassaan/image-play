#!/bin/bash

if [ $# -eq 0 ]; then
  gpu_id=0
else
  gpu_id=$1
fi

CUDA_VISIBLE_DEVICES=$gpu_id th main.lua \
  -expID hg-256-res-clstm-res-64 \
  -nThreads 4 \
  -nEpochs 4 \
  -batchSize 3 \
  -testInt 6600 \
  -weightProj 1e-6 \
  -netType hg-256-res-clstm-res-64 \
  -hgModel ./pose-hg-train/exp/penn_action_cropped/hg-256-ft/best_model.t7 \
  -s3Model ./skeleton2d3d/exp/h36m/res-64/model_best.t7 \
  -evalOut hg
