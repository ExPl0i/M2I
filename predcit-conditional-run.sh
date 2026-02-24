CUDA_VISIBLE_DEVICES=0,1; \
OUTPUT_DIR=/data/output; \
DATA_DIR=/data/training_interactive/; \
RELATION_GT_DIR=/data/relation_gt/training_interactive_gt_relations.pickle; \
RELATION_PRED_DIR=./m2i.relation.v2v.VAL; \
INFLUENCER_PRED_DIR=./validation_interactive_m2i_v.pickle; \
python -m src.run --waymo --data_dir ${DATA_DIR} \
--output_dir ${OUTPUT_DIR} --config conditional_pred.yaml \
--relation_file_path ${RELATION_GT_DIR} \
--relation_pred_file_path ${RELATION_PRED_DIR} \
--influencer_pred_file_path ${INFLUENCER_PRED_DIR} \
--future_frame_num 80 \
-e --eval_rst_saving_number 0 \
--eval_exp_path ${RESULT_EXPORT_PATH}