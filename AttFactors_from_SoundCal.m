
directory = 'C:\Users\dariy\Desktop\SoundCalibrationBackUp\UltrasonicSpeakers';
data_table = create_attenuation_table(directory);

function attenuation_table = create_attenuation_table(folder_path)
% Define frequency range
freq_range = 500:500:20000;

% Get a list of all .mat files in the specified folder
mat_files = dir(fullfile(folder_path, '*.mat'));

% Get a number of columns
num_soundcal = numel(mat_files);

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
    idx = ismember(freq, freq_range); %is array freq inside freq_range
    temp_col(idx) = attenuation(idx);
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
    disp('loop done')
    %attenuation_table.Properties.VariableNames = [attenuation_table.Properties.VariableNames, date];
end
% Save as an Excel file (requires Excel Link Toolbox)
writetable(attenuation_table, 'attenuation_table.xlsx');
end