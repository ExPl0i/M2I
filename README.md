# M2I: ответвление для дипломного проекта env-predict

Ответвление репозитория [Tsinghua-MARS-Lab/M2I](https://github.com/Tsinghua-MARS-Lab/M2I) для дипломного проекта [env-predict](https://github.com/ExPl0i/env-predict). Здесь используется для совместного прогноза траекторий пары взаимодействующих транспортных средств на части `validation_interactive` набора Waymo Open Motion Dataset v1.3.1. Описание авторов приведено ниже без изменений.

## Изменения относительно оригинала

- `Dockerfile`: образ на основе `nvidia/cuda:11.1.1-cudnn8-runtime-ubuntu20.04`. Python 3.6.15 собирается из исходников (в Ubuntu 20.04 нет пакета Python 3.6), загрузка архива повторяется при сбоях и при необходимости берется с зеркала или с GitHub. Версии pip ниже 22 и setuptools ниже 60 закреплены для совместимости с Python 3.6. Далее ставятся PyTorch 1.8.1 (CUDA 11.1), TensorFlow 2.4.0 и waymo-open-dataset-tf-2-4-0 1.3.0 с версиями библиотек из `conda.cuda111.yaml`; расширение Cython собирается при сборке образа.
- `docker-run.sh`: запуск контейнера на двух видеокартах с подключением данных Waymo Open Motion Dataset и рабочих папок проекта.
- Скрипты запуска этапов M2I:
  - `predict-relation-run.sh`: прогноз отношения «влияющий – реагирующий» предобученной моделью авторов `m2i.relation.v2v` (эпоха 25);
  - `predict-marginal-run.sh`: маргинальный прогноз влияющего участника моделью `waymo.densetnt.raster.vehicle.3`, обученной в проекте командой из раздела Training Marginal Predictor ниже; результат `influencer_pred_val.pickle`;
  - `training-conditional-run.sh`: обучение условного предиктора реагирующего участника (пары «транспортное средство – транспортное средство», две видеокарты, размер пакета 32);
  - `predcit-conditional-run.sh`: условный прогноз весами после эпохи 29, результат `my_conditional_run1.pickle`.
- `src/run.py`: при оценке условного предиктора из пятимерного массива прогнозов берется нужное измерение перед расчетом метрик Waymo; папка для результатов создается автоматически.
- `src/structs.py`, `src/utils.py`: сохранение результатов в папку, которой еще нет, и запуск оценки без заранее созданной выходной папки.

## Порядок запуска

1. Собрать образ: `docker build -t expl0i/m2i:cu111u20v2 .`
2. Поправить пути к данным в `docker-run.sh` и запустить контейнер: `bash docker-run.sh`
3. Внутри контейнера (`docker exec -it m2i bash`, папка `/workspace/M2I`) по очереди выполнить `predict-relation-run.sh`, `predict-marginal-run.sh`, `training-conditional-run.sh`, `predcit-conditional-run.sh`.

Нужные файлы авторов (истинные отношения `training_interactive_gt_relations.pickle` и `validation_interactive_gt_relations.pickle`, предобученная модель отношений `m2i.relation.v2v`) скачиваются по ссылке на Google Drive из описания ниже.

## Где хранятся веса и прогнозы

Веса условного предиктора (эпохи 29 и 30) и прогнозы `my_conditional_run1.pickle` хранятся в приватном датасете [ExPl0i/env-predict-data](https://huggingface.co/datasets/ExPl0i/env-predict-data), набор `models`. Прогнозы импортированы в выгрузку веб-приложения (набор `ui_bundle_m2i`) под именем модели `m2i_conditional_1`.

---

# M2I: From Factored Marginal Trajectory Prediction to Interactive Prediction

[Paper](https://arxiv.org/abs/2202.11884) [Project Page](https://tsinghua-mars-lab.github.io/M2I/)

## Overview

This repository can be used for reproducing the result we published in our paper. We are constantly working on modeling interactions for road users and planning/prediction-focused simulations. Follow us on Google Scholar for our latest works on these interesting topics.

What you can expect in this repository 🤟:

* Code to predict with pre-trained relation predictor
* Code to predict with pre-trained marginal trajectory predictor
* Code to predict with pre-trained conditional trajectory predictor
* Code to train the relation predictor on WOMD
* Code to train the marginal trajectory predictor on WOMD
* Code to train the conditional trajectory predictor on WOMD

What you might not find in this repository 😵:

* Code to generate the ground truth label, but you can download the labels we used to train our relation predictor
* The simulator we used for visualization, but you can use the visualization toolkits provided from Waymo as an alternative
* Code to pack and submit the prediction results to the Waymo Interactive Motion Prediction Challenge


## Prepare Your Dataset

Login and download the dataset from the [Waymo Open Dataset](https://waymo.com/open/data/motion/#). We used the tf.Example proto file from the interactive validation/testing dataset.  

As only a subset of scenarios in the **training** dataset has annotated interactive agents,
we provide a script to filter out interactive scenarios from training data. Details are [provided below](#filtering-interactive-training-data).

## Cython

Our `run.py` script includes the code to compile the Cython script `utils_cython.pyx` on each run. In case that does not work out on your machine, use the following command to compile instead.

``` bash
cd src
cython -a utils_cython.pyx && python setup.py build_ext --inplace
```

## Quick Start

Requires:

* Python 3.6
* PyTorch 1.6+

Install packages into a Conda environment (Cython, tensorflow, waymo-open-dataset, etc.):

``` bash
conda env create -f conda.cuda111.yaml
conda activate M2I
```

Download our prediction results and our pre-trained models from [Google Drive](https://drive.google.com/drive/u/2/folders/1SH8HWu8DQtwUgSFoIJOL8vJEvgFptBCD), then you can run the following commands for a quick prediction.

### Relation Prediction
Download our relation prediction results `m2i.relation.v2v.VAL` on the interactive validation dataset, 
or download the ground truth label `validation_interactive_gt_relations.pickle` and 
the pre-trained relation model `m2i.relation.v2v.zip` (unpack first) to run the following command to predict. 
Download and unpack to the project folder to load.

```  bash
OUTPUT_DIR=m2i.relation.v2v; \
DATA_DIR=./validation_interactive/; \
RELATION_GT_DIR=./validation_interactive_gt_relations.pickle; \
python -m src.run --waymo --data_dir ${DATA_DIR} \
--config relation.yaml --output_dir ${OUTPUT_DIR} \
--future_frame_num 80 \
--relation_file_path ${RELATION_GT_DIR} --agent_type vehicle \
--distributed_training 1 -e --nms_threshold 7.2 \
--validation_model 25 --relation_pred_threshold 0.9
```

### Marginal Trajectory Prediction
Download the marginal prediction results `validation_interactive_m2i_v.pickle` on the interactive validation dataset, 
or run the following command to predict with the pre-trained marginal prediction model `densetnt.raster.vehicle.1.zip` (unpack first):

```  bash
OUTPUT_DIR=densetnt.raster.vehicle.1; \
DATA_DIR=./validation_interactive/; \
python -m src.run --do_train --waymo --data_dir ${DATA_DIR} \
--output_dir ${OUTPUT_DIR} --hidden_size 128 --train_batch_size 64 \
--sub_graph_batch_size 4096 --core_num 16 \
--other_params l1_loss densetnt goals_2D enhance_global_graph laneGCN point_sub_graph laneGCN-4 stride_10_2 raster train_pair_interest save_rst \
--dist 1 --future_frame_num 80 --agent_type vehicle -e --nms 7.2 --eval_exp_path validation_interactive_v_rdensetnt_full
```

### Conditional Trajectory Prediction
Download our pre-trained conditional prediction model `m2i.conditional.v2v.zip` and unpack it to predict trajectories of 
the reactors by running:

```  bash
OUTPUT_DIR=m2i.conditional.v2v; \
DATA_DIR=./validation_interactive/; \
RELATION_GT_DIR=./validation_interactive_gt_relations.pickle; \
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
```

The file `validation_interactive_gt_relations.pickle`, `m2i.relation.v2v.VAL`, `validation_interactive_m2i_v.pickle` 
can be found in the Google drive.

This command will output 6 predictions conditioned on one influencer prediction based on 
`--eval_rst_saving_number`. Change this variable from 0 to 5 to get 6 groups of conditional predictions.


## Performance

Results of this pre-trained model on the Waymo Open Motion Dataset interactive prediction benchmark:

<table class="tg">
<thead>
  <tr>
    <th class="tg-0pky">Set</th>
    <th class="tg-0pky">Type</th>
    <th class="tg-0pky">minFDE</th>
    <th class="tg-0pky">MR</th>
    <th class="tg-0pky">mAP</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-0pky" rowspan="3">Validation (8s)</td>
    <td class="tg-0pky">Vehicle</td>
    <td class="tg-0pky">5.49</td>
    <td class="tg-0pky">0.55</td>
    <td class="tg-0pky">0.18</td>
  </tr>
  <tr>
    <td class="tg-0pky">Pedstrian</td>
    <td class="tg-0pky">3.61</td>
    <td class="tg-0pky">0.60</td>
    <td class="tg-0pky">0.06</td>
  </tr>
  <tr>
    <td class="tg-0pky">Cyclist</td>
    <td class="tg-0pky">6.26</td>
    <td class="tg-0pky">0.73</td>
    <td class="tg-0pky">0.04</td>
  </tr>
  <tr>
    <td class="tg-0pky" rowspan="3">Test (8s)</td>
    <td class="tg-0pky">Vehicle</td>
    <td class="tg-0pky">5.65</td>
    <td class="tg-0pky">0.57</td>
    <td class="tg-0pky">0.16</td>
  </tr>
  <tr>
    <td class="tg-0pky">Pedstrian</td>
    <td class="tg-0pky">3.73</td>
    <td class="tg-0pky">0.60</td>
    <td class="tg-0pky">0.06</td>
  </tr>
  <tr>
    <td class="tg-0pky">Cyclist</td>
    <td class="tg-0pky">6.16</td>
    <td class="tg-0pky">0.74</td>
    <td class="tg-0pky">0.03</td>
  </tr>
</tbody>
</table>

## Training
### Filtering interactive training data
Waymo Open Dataset does not provide a separate interactive training data partition.
We provide a script to filter out interactive data from the training set:
```bash
python scripts/filter_interactive_data.py -i TRAINING_DATA_DIR -o TRAINING_INTERACTIVE_DATA_DIR
```

### Training Relation Predictor
Download the ground truth relation data `training_interactive_gt_relations.pickle` from 
Google drive and run the following command to train a relation predictor:
```bash
DATA_DIR=./training_interactive/; \
RELATION_GT_DIR=./training_interactive_gt_relations.pickle; \
python -m src.run --do_train --waymo --data_dir ${DATA_DIR} \
--output_dir ${OUTPUT_DIR} --hidden_size 128 --train_batch_size 16 --sub_graph_batch_size 1024  --core_num 16 \
--future_frame_num 80 \
--relation_file_path ${RELATION_GT_DIR} --weight_decay 0.3 --agent_type vehicle \
--other_params train_relation pair_vv \
l1_loss densetnt goals_2D enhance_global_graph laneGCN point_sub_graph laneGCN-4 stride_10_2 raster \
--distributed_training 8
```

This command trains a relation predictor for vehicle-vehicle interactions.
Replace ```pair_vv``` with ```pair_vc, pair_vp, pair_others``` to train for vehicle-cyclist, vehicle-pedestrian, and the rest type combinations, respectively.
Change the parameter `--distributed_training` or `--dist` to the number of GPUs you have for training. 

### Training Marginal Predictor
Use the following command to train a marginal predictor:
```bash
OUTPUT_DIR=waymo.densetnt.raster.1; \
DATA_DIR=./training_interactive/; \
python src/run.py --do_train --waymo --data_dir ${DATA_DIR} \
--output_dir ${OUTPUT_DIR} --hidden_size 128 --train_batch_size 64 --sub_graph_batch_size 4096 --core_num 16 \
--other_params l1_loss densetnt goals_2D enhance_global_graph laneGCN point_sub_graph laneGCN-4 stride_10_2 raster \
--dist 8 --future_frame_num 80 --agent_type vehicle
```
This command trains a marginal predictor for the vehicle type.
Change the parameter `--agent_type` to `pedestrian` or `cyclist` to train for other types' agents.

### Training Conditional Predictor
Use the following command to train the conditional predictor with the ground truth influencer trajectory and relations.
```bash
DATA_DIR=./training_interactive/; \
RELATION_GT_DIR=./training_interactive_gt_relations.pickle; \
python -m src.run --do_train --waymo --data_dir ${DATA_DIR} \
--output_dir ${OUTPUT_DIR} --hidden_size 128 --train_batch_size 64 --sub_graph_batch_size 4096  --core_num 10 \
--future_frame_num 80 --agent_type vehicle \
--relation_file_path ${RELATION_GT_DIR} --weight_decay 0.3 \
--infMLP 8 --other_params train_reactor gt_relation_label gt_influencer_traj pair_vv raster_inf raster \
l1_loss densetnt goals_2D enhance_global_graph laneGCN point_sub_graph laneGCN-4 stride_10_2 \
--distributed_training 8
```
To filter the type of agents for reactors, change the value of `--agent_type`. To filter both the type of reactors and influencers, change the flag of `pair_vv`.

# Access with License Agreement

Following the policy from Waymo, we might ask you to sign their 'Waymo Dataset License Agreement for Non-Commercial Use' by agreeing to this [page](https://waymo.com/open/licensing/) before downloading our pre-trained model.


# Citation

If you found this repo useful to your research, please consider citing

```angular2html
@inproceedings{sun2022m2i,
title={{M2I}: From Factored Marginal Trajectory Prediction to Interactive Prediction},
author={Sun, Qiao and Huang, Xin and Gu, Junru and Williams, Brian and Zhao, Hang},
booktitle={Proceedings of the IEEE/CVF Conference on Computer Vision and Pattern Recognition (CVPR)},
year={2022}
}
```



