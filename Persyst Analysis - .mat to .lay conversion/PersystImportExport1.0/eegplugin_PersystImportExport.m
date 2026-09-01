% [version] = eegplugin_eegplugin_PersystImportExport(fig, try_strings, catch_strings) - EEGlab plugin
%
% Import EEG recordings in Persyst layout format
% Export EEG recordings in Persyst layout format
%
%
% Author: maarten.schrooten@uzleuven.be, Dec 2018
%
% Licence: see licence.txt

% Changes:
% - 2018-12-01 version 1.0
%     first version

function [version] = eegplugin_PersystImportExport(fig, try_strings, catch_strings)

%% Version
version = 'Persyst Import/Export v1.0';

%% Find menu(s)
import_menu = findobj(fig, 'tag', 'import data');
export_menu = findobj(fig, 'tag', 'export');

%% Create command(s)
cmd_import_persyst = [ try_strings.no_check '[EEG LASTCOM] = pop_import_persyst();'    catch_strings.store_and_hist];
cmd_export_persyst = [ try_strings.no_check '[EEG LASTCOM] = pop_export_persyst(EEG);' catch_strings.store_and_hist];

%% create submenu(s)
uimenu(import_menu, 'label', 'From Persyst .LAY file',   'tag', 'From Persyst .LAY file',  'callback', cmd_import_persyst, 'separator', 'on' );
uimenu(export_menu, 'label', 'Write Persyst .LAY file',  'tag', 'Write Persyst .LAY file', 'callback', cmd_export_persyst, 'separator', 'on' );

%% Function end
end
