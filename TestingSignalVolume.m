% Load txt file with signal testing
directory = 'C:\Users\dariy\Desktop\CalibrationSoundNewSpeakers\GenerateSinWave';
filename = fullfile(directory, '20240806SoundCal2024080590degreesFoam10ssignalnoiseplus6dB.txt');

soundcal_filename = 'SoundCalibration20240805digAtt109to16kHztarget90dB.mat';
soundcal_dir = 'C:\Users\dariy\Desktop\SoundCalibrationBackUp\UltrasonicSpeakers';
soundcal_filename = fullfile(soundcal_dir, soundcal_filename);

[freq_vec_rew_signal, volumes_rew] = plot_REW_data(filename, soundcal_filename);

function [freq_vec_rew_signal, volumes_rew] = plot_REW_data(filename, soundcal_filename)

% Open the file
fileID = fopen(filename, 'r');

% Read header information
header = textscan(fileID, '%s', 20, 'Delimiter', ':');
%header = importdata(filename, ' ', 11);
fclose(fileID);

% Extract relevant header information
start_time = str2double(header{1, 1}(14)); % Assuming format 'Start: 1722944920005'
log_interval = strsplit(header{1,1}{18}, ' seconds');
log_length = strsplit(header{1,1}{16}, ' entries');
log_length = str2double(log_length{1});
log_interval = str2double(log_interval{1});

% Read data

fileID = fopen(filename, 'r');

% Skip the first 11 lines
for i = 1:11
    fgetl(fileID);
end

% Read the data
data = textscan(fileID, '%f %f %f %f %f %f %f %f %f %s', 'Delimiter', ' ');
fclose(fileID);

% Convert time to numeric format
time_str = data{10};
time_num = zeros(size(time_str));
for i = 1:length(time_str)
    time_parts = strsplit(time_str{i}, ':');
    time_num(i) = str2double(time_parts{1})*3600 + str2double(time_parts{2})*60 + str2double(time_parts{3});
end

% Extract other data
LAF = data{2};

% Plot LAF as an example
figure
t = tiledlayout(1, 3);
t.Padding = 'compact';
t.TileSpacing = 'compact';
set(gcf, 'Position',  (1.0e+03)*[0.0080    0.1785    1.2800    0.3960])
ax1 = nexttile(t);
plot(LAF);
xlabel('Time');
ylabel('LAF (dB)');
title('REW Data');
grid on;


%% SECTION2: Select the points of the peak around specific volume 
% for signal volume of 10 sec / log_interval = 117.1875 REW entries will be
% made > the LAF entries of the signal should have ~ the same number of entries
laf_column = LAF(1221:1350);
threshold = 82;
%Plot isolated peak for 90 dB
ax2 = nexttile(t);
plot(laf_column);
len_lafentries = length(laf_column);
xlim([0 (len_lafentries+2)]);
grid on;

%% Find where Data crosses Threshold
signal_duration = 10;
signal_min = 10000;
signal_max = 15000;
SamplingRate = 192000;
SignalVolume = 90;
entries = 10/log_interval; % 117 entries for 10 sec
freq_registered_rew = (signal_max-signal_min)/entries;
freq_vec_rew = signal_min;
for i = 1:length(entries)
    freq_vec_rew(end+1) = freq_vec_rew(end)+freq_registered_rew;
end


% Initialize an array to hold the indices of threshold crossings
crossingIndices = [];

% Loop through the data to find where it crosses the threshold
for i = 2:length(laf_column) % Start from the second element to compare with the previous one
    if laf_column(i-1) < threshold && laf_column(i) >= threshold
        crossingIndices = [crossingIndices, i];
    end
end
crossingDownIndices = [];

% Loop through the data to find where it crosses the threshold again
for i = 2:length(laf_column) % Start from the second element to compare with the previous one
    if laf_column(i-1) > threshold && laf_column(i) <= threshold
        crossingDownIndices = [crossingDownIndices, i];
    end
end
med_volume_signal = median(laf_column(crossingIndices(1):crossingDownIndices(end)))
mean_volume_signal = mean(laf_column(crossingIndices(1):crossingDownIndices(end)))
len_entries = length(laf_column(crossingIndices(1):crossingDownIndices(end)))
diff_entries = len_entries-entries;
freq_gap_rew_actual = (signal_max-signal_min)/(len_entries-1);
freq_vec_rew_signal = signal_min;
for i = 1:(len_entries-1)
    freq_vec_rew_signal(end+1) = freq_vec_rew_signal(end)+freq_gap_rew_actual;
end
volumes_rew = laf_column(crossingIndices(1):crossingDownIndices(end));

% Interpolate frequency-dependent attenuation factors
load(soundcal_filename);
x = SoundCal.Table(:,1);
v = SoundCal.Table(:,2);
xq = linspace(signal_min,signal_max,SamplingRate*signal_duration);
vq = interp1(x,v,xq);
toneAtt = vq;
diffSPL = SignalVolume - [SoundCal.TargetSPL]; % Loud sounds are usually too quiet

attFactor = sqrt(10.^(diffSPL./10)); %sqrt(10.^(diffSPL./10)) in Torben's script WHY sqrt?
att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]

%att_rew = interp1(xq, att, freq_vec_rew_signal);
att_rew = [];
for i = 1:length(freq_vec_rew_signal)
    ind = find(xq==freq_vec_rew_signal(i));
    if ~isempty(ind)
        att_rew(i) = att(ind);
    else
        att_rew(i) = interp1(xq, att, freq_vec_rew_signal(i));
    end
end

% Optional: Plot the data with the crossing points marked
hold on;
plot(crossingIndices, laf_column(crossingIndices), 'rv', 'MarkerSize', 8);
hold on 
plot(crossingDownIndices, laf_column(crossingDownIndices), 'rv', 'MarkerSize', 8);
xlabel('Entry Number');
ylabel('LAF (dB)');
title_str = sprintf('%d sec Signal, LAF above %d dB', signal_duration, threshold);
title(title_str);
hold off;

ax3 = nexttile(t);
plot(freq_vec_rew_signal', volumes_rew);
title('LAF above 82 dB with attenuation factors');
xlim([signal_min, signal_max]);
xlabel('Frequencies (Hz)');
ylabel('Volume (dB)');
grid on;
hold on
yyaxis right
ylim([0, max(att_rew)]);
plot(freq_vec_rew_signal', att_rew)
ylabel('attenuation factors');

% Create the annotation text
annotation_text = sprintf('Median = %.2f \n Mean = %.2f \n Entries = %d', med_volume_signal, mean_volume_signal, len_entries);
% annotation(ax2, 'textbox', [.2 .5 .3 .3], 'String', annotation_text, 'FitBoxToText', 'on');
text(ax2, 0.5, 0.5, annotation_text, 'Units', 'normalized', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
filename_fig = split(filename, '.');
filename_fig = filename_fig{1};
saveas(gcf, filename_fig, 'png');
end


