%% createEEGlabDemoDataset(eeglabDemoDataset)
%

% Creates and saves an EEGlab EEG demo dataset:
%   20 s EEG sampled at 500 Hz with channels:
%   - Fz: biphasic rectangular waves of 1 s duration and  150 µV amplitude
%   - F3: biphasic rectangular waves of 1 s duration and   75 µV amplitude
%   - F4: biphasic rectangular waves of 1 s duration and   25 µV amplitude
%   - Pz: biphasic rectangular waves of 1 s duration and -100 µV amplitude
%   - P3: biphasic rectangular waves of 1 s duration and  -50 µV amplitude
%   - P4: biphasic rectangular waves of 1 s duration and  -10 µV amplitude
%   - ECG: sine waves of 1 s duration and 200 µV amplitude
%
% Input arguments:
%   eeglabDemoDataset: path to the EEGlab demo dataset to write
%
% Dependencies:
%   EEGlab
%     https://sccn.ucsd.edu/eeglab
%
%
% Author: maarten.schrooten@uzleuven.be, Nov 2018

function createEEGlabDemoDataset(eeglabDemoDataset)

%% Load EEGlab if not already loaded
if ~exist('eeg_checkset.m', 'file'), eeglab nogui; end

%% Create EEGlab test dataset

% Start from empty set
STUDY = []; CURRENTSTUDY = 0; ALLEEG = [];
EEG = eeg_emptyset();

% Metadata
EEG.setname = 'EEGlab EEG demo dataset';
EEG.subject = 'NAME=KWS; FIRSTNAME=TESTPATIENT; EAD=27';
EEG.session = 'CNR=7834569';
EEG.comments = sprintf(['20 s EEG sampled at 500 Hz with channels:\n' ...
                        '- Fz: biphasic rectangular waves of 1 s duration and  150 µV amplitude\n' ...
                        '- F3: biphasic rectangular waves of 1 s duration and   75 µV amplitude\n' ...
                        '- F4: biphasic rectangular waves of 1 s duration and   25 µV amplitude\n' ...
                        '- Pz: biphasic rectangular waves of 1 s duration and -100 µV amplitude\n' ...
                        '- P3: biphasic rectangular waves of 1 s duration and  -50 µV amplitude\n' ...
                        '- P4: biphasic rectangular waves of 1 s duration and  -10 µV amplitude\n' ...
                        '- ECG: sine waves of 1 s duration and 200 µV amplitude\n']);

% Channels
EEG.chanlocs(end+1).labels = 'Fz';
EEG.chanlocs(end+1).labels = 'F3';
EEG.chanlocs(end+1).labels = 'F4';
EEG.chanlocs(end+1).labels = 'Pz';
EEG.chanlocs(end+1).labels = 'P3';
EEG.chanlocs(end+1).labels = 'P4';
EEG.chanlocs(end+1).labels = 'ECG';
EEG.ref = 'Ref';
EEG.nbchan = numel(EEG.chanlocs);

% Sampling / timing
EEG.srate = 500;
EEG.xmin = 0;
EEG.xmax = 20 - 1/EEG.srate + EEG.xmin;
EEG.times = EEG.xmin:1/EEG.srate:EEG.xmax;
EEG.pnts = EEG.srate * (EEG.xmax + 1/EEG.srate - EEG.xmin);
EEG.trials = 1;

% EEG signal
EEG.data = repmat([repelem(1, EEG.srate / 2) repelem(-1, EEG.srate / 2)], numel(EEG.chanlocs)-1, (EEG.xmax + 1/EEG.srate - EEG.xmin));
EEG.data = EEG.data .* [150; 75; 25; -10; -50; -100];
EEG.data(EEG.nbchan, :) = repmat(sin(2*pi*linspace(0,1-1/EEG.srate,EEG.srate)), 1, (EEG.xmax + 1/EEG.srate - EEG.xmin)) * 200;

% Events
for i = (0.5:2:20) + 0.75
    EEG.event(end+1).latency = ((EEG.xmin + 1/EEG.srate) +  i) * EEG.srate;
    EEG.event(end  ).type = 'spike';
end; clear i

% Check dataset
EEG = eeg_checkset(EEG);

% Save & plot
[filePath, fileName, fileExtension] = fileparts(eeglabDemoDataset);
EEG.filename = [fileName fileExtension];
EEG.filepath = filePath;
EEG = pop_saveset(EEG, 'filename', EEG.filename, 'filepath', EEG.filepath);
%pop_eegplot(EEG, 1, 1, 1);

% Message
fprintf('EEGlab demo dataset saved as %s.\n', eeglabDemoDataset);

end
