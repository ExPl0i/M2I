CUDA_VISIBLE_DEVICES=0,1; \
OUTPUT_DIR=/data/output; \
DATA_DIR=/data/training_interactive/; \
RELATION_GT_DIR=/data/relation_gt/training_interactive_gt_relations.pickle; \
python -m src.run --do_train --waymo --data_dir ${DATA_DIR} \
--output_dir ${OUTPUT_DIR} --hidden_size 128 --train_batch_size 32 --sub_graph_batch_size 2048  --core_num 10 \
--future_frame_num 80 --agent_type vehicle \
--relation_file_path ${RELATION_GT_DIR} --weight_decay 0.3 \
--infMLP 8 --other_params train_reactor gt_relation_label gt_influencer_traj pair_vv raster_inf raster \
l1_loss densetnt goals_2D enhance_global_graph laneGCN point_sub_graph laneGCN-4 stride_10_2 \
--distributed_training 2