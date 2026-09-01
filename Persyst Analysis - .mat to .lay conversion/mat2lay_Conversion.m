
%% .mat to .lay (Persyst) Conversion Script
% A.H.Ayyoubi - 05/16/2025

% The conversion process is as follows:
% 1. .mat -> EEGLab format (.set) (https://sccn.ucsd.edu/eeglab/)
% 2. .set -> Persyst format (.lay) (https://www.mathworks.com/matlabcentral/fileexchange/69580-persyst-lay-dat-import-export-for-eeglab)

% The code was used for spike detection using P14 in the following publication:
% "Comparative Evaluation of Automated Interictal Spike Detection Algorithms in Intracranial EEG"

% If you have any questions feel free to reach out: "ayyoubi.amirhossein@gmail.com"

clear; clc;

addpath(genpath(fullfile(pwd,'eeglab2025.0.0'))); % Make sure EEGLab is installed.
addpath(genpath(fullfile(pwd,'PersystImportExport1.0')));

eeglab;

path_directory = pwd;
original_files = dir([path_directory '/*.mat']);


w = waitbar(0,'Loading the data');

for kk = 2 % Choosing the Monopolar file
    
    msg = ['Converting - subject ',num2str(kk),' out of ',num2str(length(original_files))];
    waitbar((kk/length(original_files)),w,msg);
    
    %%% .mat to EEG format %%%
    filename = fullfile(path_directory, original_files(kk).name);
    load(filename); % Load into a temporary variable
    ntmp = strsplit(original_files(kk).name,'.');
    
    EEG = eeg_emptyset();               % Create an empty EEGLAB dataset
    EEG.data = data.data';
    EEG.nbchan = size(EEG.data, 1);     % Number of channels
    EEG.pnts   = size(EEG.data, 2);     % Number of time points
    EEG.trials = 1;                     % Number of epochs (1 if continuous)
    EEG.srate  = montage.SampleRate;    % Sampling rate in Hz (set this to match your data)
    EEG.xmin   = 0;                     % Start time in seconds (e.g., 0 or -1 depending on your epoching)
    EEG.xmax   = (EEG.pnts - 1) / EEG.srate;  % End time in seconds
    EEG.setname = ntmp{1,1}; % Optional: dataset name
    
    EEG.chanlocs = struct('labels', montage.ChannelNames');  % Your channel labels 
 
    
    EEG = eeg_checkset(EEG);
    
    ntmp = strcat(ntmp{1,1},'.set');
    pop_saveset(EEG, 'filename', ntmp, 'filepath', './');
    
    %%% EEG to Persyst format %%%
    metadata.dataType = '7'; %data format to write (e.g. '0' for signed 16 bit little endian or '7' for signed 32 bit little endian)
    metadata.montages = montage.ChannelNames;
    metadata.mainsFrequency = '60'; %60 Hz power line frequency
    metadata.firstName = 'FN';
    metadata.lastName = 'LN';
    metadata.birthDate = datetime('1989/01/01','InputFormat', 'yyyy/MM/dd','Format', 'MM/dd/yy'); % random date
    metadata.id = '111-11-1111';
    metadata.medicalRecordN = '11111111';
    
    convertEEGlabToPersyst(ntmp, metadata)
end    


