REL_MODEL_DIR=/data/relation_gt/m2i.relation.v2v
DATA_DIR=/data/validation_interactive/validation_interactive    
RELATION_GT=/data/relation_gt/validation_interactive_gt_relations.pickle

python -m src.run --waymo --data_dir ${DATA_DIR} \
  --config /workspace/M2I/configs/relation.yaml --output_dir ${REL_MODEL_DIR} \
  --future_frame_num 80 \
  --relation_file_path ${RELATION_GT} --agent_type vehicle \
  --distributed_training 1 -e \
  --nms_threshold 7.2 \
  --validation_model 25 \
  --relation_pred_threshold 0.9