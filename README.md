# iEEG Spike Detection

This repository contains demo benchmarking code and data for eight automated and established spike detection algorithms evaluated on intracranial EEG (iEEG) recordings and .mat to .lay data conversion for using Persyst as part of the study:

> **Moving Beyond Spike Detection: High Frequency Driven Masking Improves Seizure Onset Zone Localization in Intracranial EEG**
> https://onlinelibrary.wiley.com/doi/full/10.1002/epi.70449

##  Detectors Description

### 1. Detector 1: M-Det 
- **Preprocessing**: Bandpass filter [20–50 Hz]; detect peaks > 4× STD.
- **Refinement**: Filter [1–35 Hz]; normalize median rectified amplitude to 70 μV.
- **Detection Criteria**:
  - Combined half-wave amplitude > 600 μV
  - Each slope > 7 μV/ms
  - Duration ≥ 10 ms
- Reference:  https://doi.org/10.1016/j.clinph.2011.09.023

### 2. Detector 2: J-Det 
- **Preprocessing**: Downsample to 200 Hz; bandpass [8–80 Hz]; notch at 60 Hz.
- **Detection**: Envelope via Hilbert transform; threshold from log-normal fit using MLE.
- Reference: https://doi.org/10.1007/s10548-014-0379-1

### 3. Detector 3: T-Det 
- **Preprocessing**: Bandpass [1–30 Hz].
- **Detection**: Identify peaks as spike candidates.
- Reference: https://github.com/erinconrad/spike-propagation/tree/master

### 4. Detector 4: C-Det 
- **Preprocessing**: Bandpass [10–40 Hz].
- **Detection Criteria**:
  - Amplitude > 300 μV
  - Duration between 10–220 ms
  - After-going slow wave
  - Reject artifacts: high-noise segments or widespread synchronous activity (>80% channels in 400 ms window)
- Reference: https://doi.org/10.1093/brain/awz386

### 5. Detector 5: P14-Det 
- **Detection**: It applies half-wave analysis to describe IES morphology, including the preceding activity to IES, the main IES deflection, and any following slow wave. Features such as amplitude, duration, and curvature are extracted, and detections are made via a hierarchy of approximately twenty neural-network-based rules. These rules incorporate feedforward neural networks with up to 40 individual units and one to three hidden layers, depending on feature complexity
- Reference: https://doi.org/10.1016/0013-4694(95)00221-9   https://doi.org/10.1016/S1388-2457(98)00023-6

### 6. Detector 6: AIE-Det 
- **Detection**: It uses a two-stage pipeline that combines template matching with a deep residual neural network (ResNet-18). In the first stage, a template-matching procedure applies a low detection threshold to the preprocessed iEEG (notch filtered at 60Hz, band-pass filtered at 1-250 Hz and down sampled at 500 Hz) to identify all potential IES candidates. Spectrograms of these candidate events are then computed using the short-time Fourier transform (STFT). In the second stage, the resulting spectrograms are passed to a convolutional neural network (CNN) trained to classify each candidate as an IED or non-IED.
- Reference: https://doi.org/10.1016/j.clinph.2021.09.018
- Python code is provided @: https://github.com/ecoglab/aied

### 7. Detector 7: NMF-Det 
- **Detection**: The method employs unsupervised non-negative matrix factorization (NMF) to detect and localize IEDs by capturing recurring spatiotemporal patterns. It first applies a line-length (LL) transform to the iEEG, which NMF then factorizes into: (1) basis functions that reflect spatial patterns of channel involvement, and (2) an activation matrix that captures the temporal expression of those patterns. Event detection is performed by thresholding the activation matrix, while spatial localization is derived by thresholding the relevant basis vector in basis function.
- Reference: https://doi.org/10.1093/neuros/nyx480
- Python code is provided @: https://github.com/norrisjamie23/Interictal-Spike-detection

### 8. Detector 8: LL-Det 
- **Detection**: detector uses a normalized LL feature, computed by summing the absolute distance between successive samples within a sliding window and normalizing the resulting value. Events are detected by comparing the short-term LL estimate to an adaptive threshold derived from the long-term LL trend.
- Reference: https://doi.org/10.1109/IEMBS.2001.1020545

##  Dependency

The following dependencies are needed for .mat to .lay (Persyst format) conversion:
  - EEGLab: https://sccn.ucsd.edu/eeglab
  - Persyst .lay/.dat Import Export for EEGlab: https://www.mathworks.com/matlabcentral/fileexchange/69580-persyst-lay-dat-import-export-for-eeglab  

## 📜 Citation

If you use this code, please cite the corresponding papers:
- https://doi.org/10.1002/epi.70449
> **Detectors**
- M-Det: https://doi.org/10.1016/j.clinph.2011.09.023
- J-Det: https://doi.org/10.1007/s10548-014-0379-1
- T-Det: https://doi.org/10.1093/brain/awz386
- C-Det: https://doi.org/10.1093/brain/awz386
- P14-Det: https://doi.org/10.1016/0013-4694(95)00221-9   https://doi.org/10.1016/S1388-2457(98)00023-6
- AIE-Det: https://doi.org/10.1016/j.clinph.2021.09.018
- NMF-Det: https://doi.org/10.1093/neuros/nyx480
- LL-Det: https://doi.org/10.1109/IEMBS.2001.1020545

## 📬 Contact

For questions or contributions, feel free to reach out to the authors (ayyoubi.amirhossein@gmail.com).




