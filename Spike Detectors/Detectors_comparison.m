
%% iEEG Spike Detectors Comparison Script
% A.H.Ayyoubi - 08/21/2026

% The code was used for in the following publication:
% "Moving beyond spike detection: High frequency?driven masking improves seizure onset zone localization in intracranial electroencephalography."
% "Epilepsia, 2026, https://onlinelibrary.wiley.com/doi/full/10.1002/epi.70449"

% M-Det: https://doi.org/10.1016/j.clinph.2011.09.023 - "High inter-reviewer variability of spike detection on intracranial EEG addressed by an automated multi-channel algorithm"
% J-Det: https://doi.org/10.1007/s10548-014-0379-1 - "Detection of Interictal Epileptiform Discharges Using Signal Envelope Distribution Modelling: Application to Epileptic and Non-Epileptic Intracranial Recordings"
% T-Det: https://github.com/erinconrad/spike-propagation/tree/master
% C-Det: https://doi.org/10.1093/brain/awz386 - "Spatial distribution of interictal spikes fluctuates over time and localizes seizure onset"
% P14-Det: Persyst 14 Software - https://www.persyst.com/
% AIE-Det: https://doi.org/10.1016/j.clinph.2021.09.018 - "AiED: Artificial intelligence for the detection of intracranial interictal epileptiform discharges"
% NMF-Det: https://doi.org/10.1093/neuros/nyx480 - "Unsupervised Learning of Spatiotemporal Interictal Discharges in Focal Epilepsy"
% T-Det: https://doi.org/10.1109/IEMBS.2001.1020545 - "Line length: an efficient feature for seizure onset detection"

% If you have any questions feel free to reach out: "ayyoubi.amirhossein@gmail.com"

clear; clc

addpath(genpath(fullfile(pwd,'Functions')));

path_directory= pwd;
original_files=dir([path_directory '/*.mat']);

w = waitbar(0,'Loading the data');

warning off 

addpath(genpath(fullfile(pwd,'Functions')));

for kk = 1:length(original_files)
    clearvars -except kk w original_files path_directory path_directory2 original_files2
    
    msg = ['Processing - subject ',num2str(kk),' out of ',num2str(length(original_files))];
    waitbar((kk/length(original_files)),w,msg);
    
    filename=[path_directory '/' original_files(kk).name];
    load(filename);
       
    %%% Detector 1 - M-Det %%%   
    tic
    [pool.mDet.SpikeIndex, pool.mDet.ChanId, pool.mDet.SpikeFV] = mDetectSpike(data.data,montage.SampleRate);
    pool.Run_time.mDet = toc;

    %%% Detector 2 - J-Det %%%   
    [IIS_Det,pool.Run_time.JDet] = Spike_detection_function(data,montage,[],512);
        
    pool.JDet = IIS_Det.spike;
    pool.montage = montage;
 
    %%% Detector 3 - T-Det %%%
    window = 60*montage.SampleRate;
    
    tic
    [pool.TDet.spike,~,~] = fspk5(data.data,13,300,...
        length(montage.ChannelNames),montage.SampleRate,...
        window,[]);
    pool.Run_time.TDet = toc;
       
    %%% Detector 4 - C-Det %%%
    tic
    [pool.CDet.spike,~,~] = fspk6(data.data,13,300,...
        length(montage.ChannelNames),montage.SampleRate,...
        window,[]);
    pool.Run_time.CDet = toc;    
    
    %%% Detector 5 - P14-Det %%%
    % Please use Persyst software for detection
    
    %%% Detector 6 - AIE-Det %%%
    % Python code is provided @: https://github.com/ecoglab/aied
    
    %%% Detector 7 - NMF-Det %%%
    % Python code is provided @: https://github.com/norrisjamie23/Interictal-Spike-detection
    
    %%% Detector 8 - LL-Det %%%   
    tic
    [ets,ech]=LLspikedetector(data.data,montage.SampleRate);
    pool.Run_time.LineLength = toc;
    
    tmpTS = round(mean(ets,2));
    TS_list = [];
    ch_list = [];

    for i = 1:length(tmpTS)
        chIdx = find(ech(i,:));  
        TS_list = [TS_list; repmat(tmpTS(i), numel(chIdx), 1)];
        ch_list = [ch_list; chIdx(:)];
    end

    pool.LineLength.TS = TS_list;
    pool.LineLength.chInfo = ch_list;
    
    
    
    ntmp = strsplit(original_files(kk).name,'.');
    ntmp = strcat(ntmp{1,1},'-Detectors_Results.mat');
    save(ntmp,'pool','-v7.3');
end   
close(w)