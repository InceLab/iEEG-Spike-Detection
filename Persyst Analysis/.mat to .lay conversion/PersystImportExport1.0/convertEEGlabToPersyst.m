%% function convertEEGlabToPersyst(EEG, metadata)
%
% Convert an EEG in EEGlab format (.set/.fdt) into an EEG in Persyst
% format (.lay/.dat) and save it to disk.
%
% Input arguments:
%   EEG: EEGlab EEG structure or complete path to an EEGlab EEG file
%   metadata: additional metadata not included in the EEG structure
%     .dataType: data format to write (e.g. '0' for signed 16 bit little
%                endian or '7' for signed 32 bit little endian)
%     .channelMap: channel map name
%     .mainsFrequency: mains frequency to expect ('50' or '60')
%     .montages: struct with list of montage names and montage channels
%                (derivation and channel name)
%     .firstName: patient's first name
%     .middleName: patient's middle name
%     .lastName: patient's last name
%     .sex: patient's sex
%     .hand: patient's handedness ('R', 'L', 'A')
%     .birthDate: patient's date of birth (datetime)
%     .id: patient's id in Persyst
%     .medicalRecordN: patient's id in the hospital information system
%     .testDate: date of recording (datetime)
%     .testTime: time or recording (datetime)
%     .physician: physician supervising the recording
%     .technician: technician performing the recording
%     .history: patient's history
%     .medications: patient's medication
%     .comments1: additional comments
%     .comments2: additional comments
%
% Default values:
%   metadata.dataType: '0': Persyst data written to file as signed 
%                           16-bit little endian
%
%
% Dependencies:
%   EEGlab
%     https://sccn.ucsd.edu/eeglab
%   inifilePersyst (adaption from inifile)
%     https://nl.mathworks.com/matlabcentral/fileexchange/2976-inifile
%
%
% Author: maarten.schrooten@uzleuven.be, Nov 2018

function convertEEGlabToPersyst(EEG, metadata)

%% Load EEGlab if not already loaded
if ~exist('eeg_checkset.m', 'file'), eeglab nogui; end

%% Check whether EEG is a struct or a path to a file
if isstruct(EEG)
    % Proceed
    [~, fileName, ~] = fileparts(EEG.filename);
    filePath = EEG.filepath;
elseif exist(EEG, 'file')
    % Load EEG
    [filePath, fileName, fileExtension] = fileparts(EEG);
    EEG = pop_loadset('filename', [fileName fileExtension], 'filepath', filePath);
    EEG.filename = [fileName fileExtension];
    EEG.filepath = filePath;
else
    % Error
    error('First parameter should be an EEGlab EEG structure or a complete path to an EEGlab EEG file.');
end

%% Convert to Persyst layout format

% Persyst Layout File (.lay)
%
% The Persyst Layout File is a text file that is created when any recording that is being
% reviewed is saved. It allows users to place text comments in a recording from Insight and
% save them without having to modify the source's event file. It also accompanies any data
% that is exported from Insight. Exported data is saved as interleaved 16-bit signed binary.
% The channels saved are those in the raw recording (Recorded montage). A *.lay file contains
% the header information needed to decode the data, channel names, calibration value
% (µV/bit), etc. This is a text file that may be easily read by custom programs that you
% develop.
%
% The section headings that are in the layout file are:
%   [FileInfo] (all files)
%   [ChannelMap] (exported files)
%   [Sheets] (source files)
%   [VPlotGroups] (all files)
%   [Comments] (all files)
%   [Patient] (exported files)

% Determine data type and a calibration for an approximate range of -5 mV to 5 mV
if isfield(metadata, 'dataType')
    dataType = metadata.dataType;
else
    dataType = '0'; % default: signed 16-bit little endian
end
if ~isfield(metadata, 'calibration') || isempty(metadata.calibration)
    switch dataType
        case '0' % signed 16-bit little endian
            calibration =  '0.152587890625000000000'; ... % in µV/bit
        case '4' % signed 16-bit big endian
            calibration =  '0.152587890625000000000'; ... % in µV/bit
        case '6' % signed  8-bit little endian
            calibration = '39.062500000000000000000'; ... % in µV/bit
        case '7' % signed 32-bit little endian
            calibration =  '0.000002328306436538700'; ... % in µV/bit
        otherwise
            error('Unknown data type');
    end
else
    calibration = metadata.calibration;
end

% Create a new .lay-file (.ini-file)
inifilePersyst(fullfile(filePath, [fileName '.lay']), 'new');

% Construct the keys to write to the .lay file
writeKeys = [];

% [FileInfo]
writeKeys = [writeKeys; ...
            {'FileInfo',    '', 'File',           fullfile(filePath, [fileName '.dat']); ...
             'FileInfo',    '', 'FileType',       'Interleaved'; ...         % interleaved
             'FileInfo',    '', 'SamplingRate',   num2str(EEG.srate); ...    % in Hz
             'FileInfo',    '', 'HeaderLength',   '0'; ...                   % number of bytes in the header (no header)
             'FileInfo',    '', 'Calibration',    calibration; ...           % in µV/bit
             'FileInfo',    '', 'WaveformCount',  num2str(EEG.nbchan); ...   % ?
             'FileInfo',    '', 'DataType',       dataType}];                % DataType=0 > 16-bit signed (little endian); DataType=4 > 16-bit (big endian); DataType=6 > 8 bit signed; DataType=7 > 32-bit signed
if isfield(metadata, 'channelMap')
writeKeys = [writeKeys; ...
            {'FileInfo',    '', 'ChannelMap',     metadata.channelMap}];
end
if isfield(metadata, 'mainsFrequency')
writeKeys = [writeKeys; ...
            {'FileInfo',    '', 'MainsFrequency', metadata.mainsFrequency}];
end

% [Montage]: montage names
if isfield(metadata, 'montages')
for i = 1:numel(metadata.montages)
if isfield(metadata.montages(i), 'name')
writeKeys = [writeKeys; ...
            {'Montage',     '', metadata.montages(i).name, NaN}];
end
end
% [Montage]: individual montages
if isfield(metadata.montages, 'name') && isfield(metadata.montages, 'channels')
for i = 1:numel(metadata.montages)
for j = 1:size(metadata.montages(i).channels, 1)
writeKeys = [writeKeys; ...
            {metadata.montages(i).name, '', metadata.montages(i).channels{j,1}, metadata.montages(i).channels{j,2}}];
end; clear j
end; clear i
end % channels
end % montages

% [SampleTimes]: clock time vs. elapsed time; also used to show clock time when there are pauses during the recording
if isfield(metadata, 'testDate') && isfield(metadata, 'testTime') && ...
   isdatetime(metadata.testDate) && isdatetime(metadata.testTime)
% register clock time for first sample; breaks/recording interruptions not supported for now
testDate     = datetime(metadata.testDate, 'Format', 'yyyy/MM/dd HH:mm:ss.SSS');
testDateTime = datetime(metadata.testTime, 'Format', 'yyyy/MM/dd HH:mm:ss.SSS');
writeKeys = [writeKeys; ...
            {'SampleTimes', '', '0', sprintf('%1.3f', seconds(testDateTime-testDate))}];
else
% ignore clock time
writeKeys = [writeKeys; ...
            {'SampleTimes', '', '0', '0.000'}];
end

% [ChannelMap]: describe channel labels
if isfield(EEG, 'event')
for i = 1:numel(EEG.chanlocs)
    writeKeys = ...
            [writeKeys; ...
            {'ChannelMap',  '', sprintf('%s-%s', EEG.chanlocs(i).labels, EEG.ref), i}];
end; clear i
end

% % [Sheets]: Insight II feature; deprecated in Persyst; save select pages
%             in a recording with a tabbed display layout with selected
%             gain/montage/filter settings
% writeKeys = [writeKeys; ...
%             {'Sheets',      '', 'Patient', NaN; ...
%              'Sheets',      '', 'Review', NaN; ...
%              'Sheets',      '', 'Tab1', NaN}];
% % [Tab1]
% writeKeys = [writeKeys; ...
%             {'Tab1',        '', 'Speed', '10 sec'; ...
%              'Tab1',        '', 'Sensitivity', '50 µV'; ...
%              'Tab1',        '', 'Zoom', '1x'; ...
%              'Tab1',        '', 'Montage', 'Recorded'; ...
%              'Tab1',        '', 'HiFilter', '70 Hz'; ...
%              'Tab1',        '', 'TimeConstant', '0.1 sec'; ...
%              'Tab1',        '', 'Notch', '50 Hz'; ...
%              'Tab1',        '', 'MajorGrid', '1'; ...
%              'Tab1',        '', 'MinorGrid', '0'; ...
%              'Tab1',        '', 'Comments', '1'; ...
%              'Tab1',        '', 'CommentLines', '0'; ...
%              'Tab1',        '', 'Times', '1'; ...
%              'Tab1',        '', 'HighResolution', '0'; ...
%              'Tab1',        '', 'NegativeUp', '1'; ...
%              'Tab1',        '', 'CalibrationMark', '0'; ...
%              'Tab1',        '', 'XScroll', '0.000000'}];

% % [VPlotGroups]
% writeKeys = [writeKeys; ...
%             {'VPlotGroups', '', 'ECG,spike', ''}];

% [Comments]: events
if isfield(EEG, 'event')
for i = 1:numel(EEG.event)
    if ~isfield(EEG.event(i), 'duration') || isempty(EEG.event(i).duration), EEG.event(i).duration = 0; end
    writeKeys = ...
            [writeKeys; ...
            {'Comments', ...
             '', ...
             sprintf('%1.5f,%1.5f,0,100,%s', ...
                     (EEG.event(i).latency-1) / EEG.srate, ...
                     (EEG.event(i).duration)  / EEG.srate, ...
                     EEG.event(i).type), ...
             ''}];
end; clear i
end

% [Patient]: patient information
for field = {{'firstName'      'First'} ...
             {'middleName'     'MI'} ...
             {'lastName'       'Last'} ...
             {'sex'            'Sex'} ...
             {'hand'           'Hand'} ...
             {'birthDate'      'BirthDate'} ...
             {'id'             'ID'} ...
             {'medicalRecordN' 'MedicalRecordN'} ...
             {'testDate'       'TestDate'} ...
             {'testTime'       'TestTime'} ...
             {'physician'      'Physician'} ...
             {'technician'     'Technician'} ...
             {'history'        'History'} ...
             {'medications'    'Medications'} ...
             {'comments1'      'Comments1'} ...
             {'comments2'      'Comments2'}}
if isfield(metadata, field{1}{1})
if isdatetime(metadata.(field{1}{1}))
writeKeys = [writeKeys; ...
            {'Patient',     '', field{1}{2}, datestr(metadata.(field{1}{1}), lower(metadata.(field{1}{1}).Format))}];
elseif ischar(metadata.(field{1}{1}))
writeKeys = [writeKeys; ...
            {'Patient',     '', field{1}{2}, strrep(strrep(metadata.(field{1}{1}), '\r', ''), '\n', '; ')}];
else
writeKeys = [writeKeys; ...
            {'Patient',     '', field{1}{2}, metadata.(field{1}{1})}];
end
end
end

% Write layout file (.ini-like file) without sorting
inifilePersyst(fullfile(filePath, [fileName '.lay']), 'write', writeKeys, 'plain', 'off');

% Persyst Data File (.dat)
%
% The data is saved as interleaved 16-bit signed binary with a '.dat' extension. The channels
% saved are those in the raw recording (Recorded montage). A *.lay file contains the header
% information needed to decode the data, channel names, calibration value (µV/bit), etc. This
% is a text file that may be easily read by custom programs that you develop.
% The interleaved 16 bit signed data is in Intel byte-order (little endian). I believe signed 
% binary is always 2s complement, but if you simply read the data into a buffer of short int,
% then you'll be fine.
% Multiply the short ints by the calibration value (µV/bit) to get the µV values. Interleaved
% means the storage is: sample-0 of channel-0, sample-0 of channel-1, ..., sample-1 of
% channel-0, ....

datFileId = fopen(fullfile(filePath, [fileName '.dat']), 'w');
[~, ~, endian] = computer;
switch endian
    case 'L' % working on little endian system
        switch dataType
            case '0' % signed 16-bit little endian
                count = fwrite(datFileId,           int16(reshape(EEG.data, 1, EEG.nbchan * EEG.pnts) / str2double(calibration)),  'int16');
            case '4' % signed 16-bit big endian
                count = fwrite(datFileId, swapbytes(int16(reshape(EEG.data, 1, EEG.nbchan * EEG.pnts) / str2double(calibration))), 'int16');
            case '6' % signed  8-bit little endian
                count = fwrite(datFileId,           int8( reshape(EEG.data, 1, EEG.nbchan * EEG.pnts) / str2double(calibration)),  'int8');
            case '7' % signed 32-bit little endian
                count = fwrite(datFileId,           int32(reshape(EEG.data, 1, EEG.nbchan * EEG.pnts) / str2double(calibration)),  'int32');
            otherwise
                error('Unknown data type');
        end
    case 'B' % working on a big endian system
        switch dataType
            case '0' % signed 16-bit little endian
                count = fwrite(datFileId, swapbytes(int16(reshape(EEG.data, 1, EEG.nbchan * EEG.pnts) / str2double(calibration))), 'int16');
            case '4' % signed 16-bit big endian
                count = fwrite(datFileId,           int16(reshape(EEG.data, 1, EEG.nbchan * EEG.pnts) / str2double(calibration)),  'int16');
            case '6' % signed  8-bit little endian
                count = fwrite(datFileId, swapbytes(int8( reshape(EEG.data, 1, EEG.nbchan * EEG.pnts) / str2double(calibration))),  'int8');
            case '7' % signed 32-bit little endian
                count = fwrite(datFileId, swapbytes(int32(reshape(EEG.data, 1, EEG.nbchan * EEG.pnts) / str2double(calibration))), 'int32');
            otherwise
                error('Unknown data type');
        end
end
fclose(datFileId);

% Message
fprintf('%s.set|fdt (EEGlab) converted to %s.lay|dat (Persyst).\n', fileName, fileName);

end