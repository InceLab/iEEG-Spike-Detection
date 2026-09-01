%% showPersystDataset(persystLayoutFileName)
%
% Read a Persyst (.lay/.dat) EEG file and display it
%
% Dependencies:
%   EEGlab
%     https://sccn.ucsd.edu/eeglab
%   layread
%     https://nl.mathworks.com/matlabcentral/fileexchange/52346-read-persyst-lay-dat-files
%
%
% Author: maarten.schrooten@uzleuven.be, Nov 2018

function showPersystDataset(persystLayoutFileName)

%% Load EEGlab if not already loaded
if ~exist('eeg_checkset.m', 'file'), eeglab nogui; end

%% Read in again to verify correctness
[header, data] = layread(persystLayoutFileName);

%% Add minimal metadata
EEG = eeg_emptyset();
EEG.subject = sprintf('LAST=%s FIRST=%s ID=%s', header.patient.last, header.patient.first, header.patient.medicalrecordn);
EEG.session = header.starttime;
EEG.data = data;
EEG.nbchan = size(EEG.data, 1);
EEG.pnts = size(EEG.data, 2);
EEG.trials = size(EEG.data, 3);
EEG.srate = header.samplingrate;
EEG.xmin = 0;
EEG.xmax = (EEG.pnts-1)*(1/EEG.srate) + EEG.xmin;
EEG.times = EEG.xmin:1/EEG.srate:EEG.xmax;
for i = 1:numel(header.rawheader.channelmap)
    EEG.chanlocs(i).labels = header.rawheader.channelmap{i};
end; clear i
for i = 1:numel(header.rawheader.comments)
    elements = strsplit(header.rawheader.comments{i}, ',');
    EEG.event(i).latency = (str2double(elements{1}) * EEG.srate) + 1;
    EEG.event(i).type    = strrep(strrep(strjoin(elements(5:end),','), ...
                                         sprintf('\r'), ''), ...
                                  sprintf('\n'), '');
end; clear i
EEG.comments = sprintf('%s\n\n%s', header.rawheader.patient.comments1, header.rawheader.patient.comments2);
[filePath, fileName, fileExtension] = fileparts(persystLayoutFileName);
EEG.filename = [fileName fileExtension];
EEG.filepath = filePath;

%% Display
pop_eegplot(EEG, 1, 1, 1);

%% Message
fprintf('%s on display.\n', persystLayoutFileName);

end