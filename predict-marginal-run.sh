MARG_MODEL_DIR=/data/relation_gt/waymo.densetnt.raster.vehicle.3
DATA_DIR=/data/validation_interactive/validation_interactive

python -m src.run --do_train --waymo --data_dir ${DATA_DIR} \
  --output_dir ${MARG_MODEL_DIR} \
  --hidden_size 128 --train_batch_size 64 \
  --sub_graph_batch_size 4096 --core_num 16 \
  --other_params l1_loss densetnt goals_2D enhance_global_graph laneGCN point_sub_graph laneGCN-4 stride_10_2 raster train_pair_interest save_rst \
  --future_frame_num 80 --agent_type vehicle \
  --distributed_training 1 -e \
  --nms_threshold 7.2 \
  --eval_exp_path influencer_pred_val