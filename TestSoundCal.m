S1214digatt10 = load('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files\SoundCalibrationBackUp\UltrasonicSpeakers\SoundCalibration20231214Try2.mat');
S1214digatt30 = load('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files\SoundCalibrationBackUp\UltrasonicSpeakers\SoundCalibration20231214digAttminus30.mat');

S1214digatt60 = load('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files\SoundCalibrationBackUp\UltrasonicSpeakers\SoundCalibration20231214digAttminus60BpodRestart.mat');
S1214digatt120 = load('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files\SoundCalibrationBackUp\UltrasonicSpeakers\SoundCalibration20231214digAttminus120BpodRestartToneAtt02.mat')
figure
plot(S1214digatt10.SoundCal.Table(:,1),S1214digatt10.SoundCal.Table(:,2), '-or', S1214digatt30.SoundCal.Table(:,1), S1214digatt30.SoundCal.Table(:,2), '-og')
hold on
plot(S1214digatt60.SoundCal.Table(:,1),S1214digatt60.SoundCal.Table(:,2), '-xb', S1214digatt120.SoundCal.Table(:,1), S1214digatt120.SoundCal.Table(:,2), '-xm')
ylim([0, 0.005]);
