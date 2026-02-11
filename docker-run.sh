docker run -d --name m2i \
  --gpus '"device=0,2"' \
  --ipc=host --shm-size=8g \
  --ulimit memlock=-1 --ulimit stack=67108864 \
  --cap-add=IPC_LOCK \
  -v /mnt/scsi_nas/waymo_datasets/motion_v_1_3_1/uncompressed/tf_example/training:/data/training \
  -v /mnt/scsi_nas/env-predict/training_interactive:/data/training_interactive \
  -v /mnt/scsi_nas/env-predict/relation_gt:/data/relation_gt \
  -v /mnt/scsi_nas/env-predict/output:/data/output \
  expl0i/m2i:cu111u20 \
  tail -f /dev/null