CUDA_VISIBLE_DEVICES=0,1; \
OUTPUT_DIR=/data/output; \
DATA_DIR=/data/validation_interactive/validation_interactive; \
RELATION_GT_DIR=/data/relation_gt/validation_interactive_gt_relations.pickle; \
RELATION_PRED_DIR=/data/relation_gt/m2i.relation.v2v/pred_relations.dict.eval.model.25.bin.2026-02-26-04-20-59; \
INFLUENCER_PRED_DIR=/data/influencer_pred_val.pickle; \
RESULT_EXPORT_PATH=/data/relation_gt/my_conditional_run; \
python -m src.run --waymo --data_dir ${DATA_DIR} \
--output_dir ${OUTPUT_DIR} --config /workspace/M2I/configs/conditional_pred.yaml \
--relation_file_path ${RELATION_GT_DIR} \
--relation_pred_file_path ${RELATION_PRED_DIR} \
--influencer_pred_file_path ${INFLUENCER_PRED_DIR} \
--future_frame_num 80 \
-e --eval_rst_saving_number 1 \
--validation_model 29 \
--eval_exp_path ${RESULT_EXPORT_PATH}