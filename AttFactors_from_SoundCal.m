
directory = 'C:\Users\dariy\Desktop\SoundCalibrationBackUp\UltrasonicSpeakers\digAtt10_target90';
data_table = create_attenuation_table(directory);
plot_mean_attenuation(data_table, directory);

function attenuation_table = create_attenuation_table(folder_path)
% Define frequency range
freq_range = 500:500:20000;

% Get a list of all .mat files in the specified folder
mat_files = dir(fullfile(folder_path, '*.mat'));

% Initialize the table
attenuation_table = table(freq_range', 'VariableNames', {'Freq (Hz)'});
%emptyTable = table('Size', [length(freq_range), num_soundcal]);

for i = 1:numel(mat_files)
    disp(i)
    disp(mat_files(i).name)
    % Load the current .mat file
    load(fullfile(folder_path, mat_files(i).name));

    % Extract frequency and attenuation data

    freq = SoundCal.Table(:, 1);
    attenuation = SoundCal.Table(:, 2);
    date = SoundCal.LastDateModified;

    % Create a temporary column for the attenuation data
    temp_col = zeros(length(freq_range),1);

    % Find indices of frequencies in the defined range
    idx = ismember(freq_range, freq); %is array freq inside freq_range
    temp_col(idx) = attenuation;
    % Check if the column name (date) already exists
    if ~any(contains(attenuation_table.Properties.VariableNames, date))
        temp_col = table(temp_col, 'VariableNames', {date});
    else
        col_name = strsplit(mat_files(i).name, '.mat');
        col_name = strsplit(col_name{1}, 'SoundCalibration');
        temp_col = table(temp_col, 'VariableNames', col_name(2));
    end
    % Append the column to the attenuation table
    attenuation_table = [attenuation_table, temp_col];
end
% Save as an Excel file (requires Excel Link Toolbox)
disp('Done: Attenuation Table Created.')
table_name = fullfile(directory, 'attenuation_table.xlsx');
writetable(attenuation_table, table_name);
end

function plot_mean_attenuation(attenuation_table, directory)
% Extract frequency and attenuation data
%frequencies = str2double(attenuation_table.Properties.RowNames);
frequencies = table2array(attenuation_table(:, 1));
[row, col] = size(attenuation_table);
row_data = {};
row_mean = [];
row_std = [];
figure
for i = 1:row
    % Extract the specified row as a numeric array
    row_data{i} = table2array(attenuation_table(i, 2:end));

    % Find non-zero indices
    non_zero_indices = row_data{i} ~= 0;

    % Calculate the mean of non-zero values
    row_data{i} = row_data{i}(non_zero_indices);
    row_mean(i) = mean(row_data{i});
    row_std(i) = std(row_data{i});
    hold on 
    scatter(frequencies(i), row_data{i}, '.')
end

% Create the plot
hold on
plot(frequencies', row_mean);
xlabel('Frequency (Hz)');
ylabel('Mean Attenuation');
title('Mean Attenuation Factor vs. Frequency');
figname = fullfile(directory, 'Mean_Att_Factors_Plot');
saveas(gcf, figname, 'png');
disp('Done: Figure Saved in directory.')
end