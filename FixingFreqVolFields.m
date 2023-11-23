
% myDir = uigetdir;
% myFiles = dir(fullfile(myDir,'*.mat')); %gets all wav files in struct
%  for file = myFiles'
%    baseFileName = file.name;
%    load(fullfile(myDir, baseFileName), 'SessionData');
%    FixingDataCustomAuditoryTuning(SessionData, baseFileName, myDir);
%  end
path = "O:\data\13\bpod_session\20231123_212637";
filename = "13_AuditoryTuning_20231123_212637.mat";
load(fullfile(path, filename), "SessionData");
FixingDataCustomAuditoryTuning(SessionData, filename, path)
function FixingDataCustomAuditoryTuning(SessionData, filename, path)
if ~isfield(SessionData.Custom, 'Frequency')
    SessionData.Custom.Frequency = repmat(500:500:20000, 1, 10);
end
if ~isfield(SessionData.Custom, 'Volume')
    SessionData.Custom.Volume = repmat(60, 1, length(SessionData.Custom.Frequency));
end
outputName = fullfile(path, 'Fixed.mat');
save(outputName, "SessionData");
end