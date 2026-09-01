% [EEG LASTCOM] = pop_import_persyst() - Import Persyst .lay format
%
% Input Arguments:
% - EEG = EEGlab EEG dataset
%
% Output Arguments:
% - EEG = EEGlab EEG dataset
% - LASTCOM = last command (char)
%
% Dependencies:
%   layread
%     https://nl.mathworks.com/matlabcentral/fileexchange/52346-read-persyst-lay-dat-files
%
%
% Author: maarten.schrooten@uzleuven.be, Dec 2018
%
% Licence: see licence.txt

% Changes:
% - 2018-12-01 version 1.0

function [EEG, LASTCOM] = pop_import_persyst(persystLayoutFile)

%% Check function arguments
EEG = []; LASTCOM = [];
if nargin > 1
    % Too many arguments
    error('UNEF:TooManyArguments', 'Too many arguments')
end

%% Process file name
if nargin == 0
    % Select file GUI
    [fileName, filePath, ~] = uigetfile( ...
      {'*.lay', 'Persyt files (*.lay)';
       '*.*',   'All Files (*.*)'}, ...
       'Select an EEG in Persyt layout file format', ...
       'MultiSelect', 'on');
    % Check if user pressed cancel
    if fileName == 0
      return
    end
else
    % Process file name from argument
    [filePath, fileName, fileExtension] = fileparts(persystLayoutFile);
    fileName = [fileName fileExtension];
end

%% Read file with layread
[header, data] = layread(fullfile(filePath, fileName));

%% Add minimal metadata
% Failsafe in case of missing data
for field = {'starttime' 'samplingrate'}
    if ~isfield(header, field{1}), header.(field{1}) = []; end
end; clear field
for field = {'last' 'first' 'medicalrecordn'}
    if ~isfield(header.patient, field{1}), header.patient.(field{1}) = []; end
end; clear field
for field = {'comments' 'channelmap'}
    if ~isfield(header.rawheader, field{1}), header.rawheader.(field{1}) = []; end
end; clear field
for field = {'comments1' 'comments2'}
    if ~isfield(header.rawheader.patient, field{1}), header.rawheader.patient.(field{1}) = []; end
end; clear field
% Construct EEGlab EEG dataset
EEG = eeg_emptyset();
EEG.setname = fileName(1:end-4);
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
EEG.filename = fileName;
EEG.filepath = filePath;

%% Last command
LASTCOM = ['EEG = pop_import_persyst(''' fullfile(filePath, fileName) ''');'];

%% End of function
end