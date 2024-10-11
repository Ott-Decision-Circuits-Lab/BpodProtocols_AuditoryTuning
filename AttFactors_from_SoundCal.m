
directory = 'C:\Users\dariy\Desktop\SoundCalibrationBackUp\UltrasonicSpeakers\digAtt10_target90_10days';
data_table = create_attenuation_table(directory);
new_median_att_table = plot_mean_attenuation(data_table, directory);
% %%
% mean_attFactor_per_freq = [];
% median_attFactor_per_freq = [];
% for i = 1:40
% mean_attFactor_per_freq(i) = mean(nonzeros(table2array(data_table(i, 2:end))));
% median_attFactor_per_freq(i) = median(nonzeros(table2array(data_table(i, 2:end))));
% end
% %%
% hold on
% plot(table2array(data_table(:, 1)), median_attFactor_per_freq);

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
table_name = fullfile(folder_path, 'attenuation_table.xlsx');
writetable(attenuation_table, table_name);
end

function new_median_att_table = plot_mean_attenuation(attenuation_table, directory)
% Extract frequency and attenuation data
%frequencies = str2double(attenuation_table.Properties.RowNames);
frequencies = table2array(attenuation_table(:, 1));
[row, col] = size(attenuation_table);
row_data = {};
row_mean = [];
row_std = [];
att_factors_cleared = {};
att_factors_cleared_median = [];
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
    att_factors_cleared{i} = rmoutliers(row_data{i}, "gesd");
    att_factors_cleared_median(i) = median(att_factors_cleared{i});
end
% New SoundCal file
new_median_att_table(:, 1) = frequencies;
new_median_att_table(:, 2) = att_factors_cleared_median;
% Setup struct
SoundCal = struct;
SoundCal.Table = new_median_att_table;
SoundCal.CalibrationTargetRange = [frequencies(1), frequencies(end)];
SoundCal.TargetSPL = 90; %ENTER HERE
SoundCal.LastDateModified = char(datetime("today"));
SoundCal.Coefficient = polyfit(new_median_att_table(:,1)',new_median_att_table(:,2)',1);
SoundCal.digAtt = -10; %ENTER HERE
SoundCal.nSpeakers = 1; %ENTER HERE


file_name =  'SoundCalibration_Median_AttFactors_No_Extreme_Outliers.mat';
full_filename = fullfile(directory,file_name);
save(full_filename, "SoundCal");
disp('Done: new SoundCal with rmOutliers saved in directory.')

% Create the plot
hold on
plot(frequencies', row_mean, 'b-');
xlabel('Frequency (Hz)');
ylabel('Mean Attenuation');
title('Mean Attenuation Factor vs. Frequency');
figname = fullfile(directory, 'Mean_Att_Factors_Plot');
saveas(gcf, figname, 'png');
disp('Done: Figure Saved in directory.')

% Remove outliers
figure
for i = 1:row
    hold on
    scatter(frequencies(i), att_factors_cleared{i}, '.')
end
hold on
plot(frequencies', att_factors_cleared_median, 'r-');
xlabel('Frequency (Hz)');
ylabel('Median Attenuation, No Outliers');
ylim([0, 1])
title('Median Attenuation Factor, no Outliers vs. Frequency');
figname = fullfile(directory, 'Median_AttFactors_rmOutliers_Plot');
saveas(gcf, figname, 'png');
disp('Done: Figure 2 Saved in directory.')
end