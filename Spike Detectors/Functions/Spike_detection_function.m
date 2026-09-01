function [Pool,Exec_time] = Spike_detection_function(data,montage,corrupted_Ch,spike_Win,filt_freq,Amp_th_min,th_mult)

% Spike Detection function for Spike/HFO analysis study

% Amir Hossein Ayyoubi - 04/26/2024
%
% Inputs:
% data: Raw input data in the format of data.data.
% montage: Recording montage file.
% corrupted_Ch: Vector of corrupted channels index such as: corrupted_Ch = [18,19,66];
% spike_Win: Window size for saving the events. The unit is number of samples.
% filt_freq: Bandpass frequency for saving the filtered data. [10,80] by default.
% Amp_th_min: threshold on raw data for denoising. 50uV by default.
% 
% Outputs:
% Pool: Contains: 1.Raw events 2.Filtered events 3.Analysis statistics(number of detected spikes in each channel)...
%                 4.Events timestamps 5.events channels information 6.Spikes denoising results
            


if nargin ==2
    corrupted_Ch = [];
    spike_Win = 500; %500 samples
    filt_freq = [10,80]; %10-60Hz frequency band for filtering
    Amp_th_min = 85; %85uV threshold on raw data for denoising
    th_mult = 3;
%     Amp_th_max = 4000;
elseif nargin ==3
    spike_Win = 500; %500 samples
    filt_freq = [10,80]; %10-60Hz frequency band for filtering
    Amp_th_min = 85; %85uV threshold on raw data for denoising
    th_mult = 3;
%     Amp_th_max = 4000;
elseif nargin ==4
    filt_freq = [10,80]; %10-60Hz frequency band for filtering
    Amp_th_min = 85; %85uV threshold on raw data for denoising
    th_mult = 3;
%     Amp_th_max = 4000;
elseif nargin ==5
    Amp_th_min = 85; %85uV threshold on raw data for denoising
    th_mult = 3;
%     Amp_th_max = 4000;
elseif nargin ==6
    th_mult = 3;
%     Amp_th_max = 4000;
elseif nargin<2     
    error('Not enough input argument');
end

y = data.data;
% y = data;
fs = montage.SampleRate;

% initialization
% events_pos_preproce = cell(size(y,2),1);
events_num_preproce = zeros(size(y,2),1);
% events_pos_postproce = cell(size(y,2),1);
events_num_postproce = zeros(size(y,2),1);

warning off

initial_results = [NaN,NaN,NaN]; % initialization
% Spike detectio
for ii = 1 : size(y,2)
    
    if sum(ismember(corrupted_Ch,ii))  == 0 %Not doing the spike detection over corrupted channels
        d = y(:,ii);
        
        [b1,a1] = butter(2,1/(fs/2),'high'); %1Hz filtering to remove the DC
        df1 = filtfilt(b1,a1,d);
        
        settings_param = ['-fl ',num2str(filt_freq(1)),' -fh ',num2str(filt_freq(2)),' -k1 ',num2str(th_mult)];
        tic
        DE=spike_detectorV24(d,fs,settings_param);
        Run_time(ii) = toc;
        
        if ~isempty(DE.pos)
            tmp_initial_results(:,2) = round(DE.pos.*fs); % Temporary initial results
            tmp_initial_results(:,1) = ii;
            tmp_initial_results(:,3) = 1;
            initial_results = cat(1,initial_results,tmp_initial_results); % Initial detection results - before post processing
            clear tmp_initial_results;
        end
        % Saving the initial detection results
        events_num_preproce(ii) = length(DE.pos);
%         events_pos_preproce{ii,1} = DE.pos;
        
        % post processing
        if ~isempty(DE.pos)
            for jj = 1 : length(DE.pos)
                sp_win = df1(DE.pos(jj)*fs - 150:DE.pos(jj)*fs + 150,1);
                if peak2peak(sp_win)< Amp_th_min %|| peak2peak(sp_win)> Amp_th_max
                    DE.pos(jj) = NaN; % removing the events with raw amp less than the predefined threshold
                    idx = size(initial_results,1) - length(DE.pos) + jj;
                    initial_results(idx,3) = 0;
                end
            end
            
            DE.pos(isnan(DE.pos)) = [];
            % Saving the post processing results
            events_num_postproce(ii) = length(DE.pos);
%             events_pos_postproce{ii,1} = DE.pos;
            
            % for distance constraint over the detected events
            
            %     min_event_diff = 0.3; %300ms
            %     if ~isempty(DE.pos)
            %         NK_events_post = DE.pos(1);
            %         for i = 2:length(DE.pos)
            %             if DE.pos(i) - NK_events_post(end) > min_event_diff
            %                 NK_events_post(end+1) = DE.pos(i);
            %             end
            %         end
            %     else
            %         NK_events_post = [];
            %     end
            %     NK_events_postpro(ii) = length(NK_events_post);
            
        else
            %nothing
        end
    else
        %nothing
    end
end
Exec_time = sum(Run_time);

initial_results(1,:) = []; %removing the NaN in the first row
initial_results = sortrows(initial_results, 2); % sorting the events based on the occurrence time

[b2,a2] = butter(2,filt_freq/(fs/2),'bandpass'); %band pass filtering the signal
y_filt = filtfilt(b2,a2,y);

if spike_Win == 512
    for ii = 1:size(initial_results,1)
        Pool.spike.events.Raw(ii,:) = y(initial_results(ii,2)-spike_Win:initial_results(ii,2)+spike_Win-1,initial_results(ii,1));
        Pool.spike.events.Filtered(ii,:) = y_filt(initial_results(ii,2)-spike_Win:initial_results(ii,2)+spike_Win-1,initial_results(ii,1));
    end
else
    for ii = 1:size(initial_results,1)
        Pool.spike.events.Raw(ii,:) = y(initial_results(ii,2)-spike_Win:initial_results(ii,2)+spike_Win-1,initial_results(ii,1));
        Pool.spike.events.Filtered(ii,:) = y_filt(initial_results(ii,2)-spike_Win:initial_results(ii,2)+spike_Win-1,initial_results(ii,1));
    end
end
% saving the results in the Pool
% Pool.spike.stat.pos_initial = events_pos_preproce; %statistics
Pool.spike.stat.num_initial = events_num_preproce; %statistics
% Pool.spike.stat.pos_denoised = events_pos_postproce; %statistics
Pool.spike.stat.num_denoised = events_num_postproce; %statistics

Pool.spike.timestamp = initial_results(:,2);
Pool.spike.Channelinformation = initial_results(:,1);
Pool.spike.Denoising = initial_results(:,3); %if 1 = spike, if 0 = small discharges

end
