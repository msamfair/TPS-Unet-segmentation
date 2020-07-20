# TPS-Unet-segmentation
A semantic segmentation workflow for working with TPS files

Overview

transfermodel_utils.PrepareData: prepares PNG images and PNG binary masks for model training (masks created using mask_from_tps.R and tps-oo.R)

train_transferlearning: trains a Unet model via transfer learning using the segmentation_models library

make_predictions: uses the trained model to predict the outlines of specimens and writes them to txt files

transfermodel_utils.WriteMultipletoTPS: writes a TPS file for the segmented outlines of however many specimens


Citing

@misc{msamfairGitHub,
  Author = {Maya Samuels-Fair and Gene Hunt},
  Title = {TPS Unet Segmentation},
  Year = {2020},
  Publisher = {GitHub},
  Journal = {GitHub repository},
  Howpublished = {\url{https://github.com/msamfair/TPS-Unet-segmentation}}
}


References

Singhal, P (2019) unet_test.py. https://medium.com/@pallawi.ds/semantic-segmentation-with-u-net-train-and-test-on-your-custom-data-in-keras-39e4f972ec89.

Singhal, P (2019) unet_2.py. https://medium.com/@pallawi.ds/semantic-segmentation-with-u-net-train-and-test-on-your-custom-data-in-keras-39e4f972ec89.

Yakubovskiy, P (2019) segmentation_models. https://github.com/qubvel/segmentation_models.

Developed in Python 3.7, Tensorflow 1.15, R 3.6.1
