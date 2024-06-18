% quick script to test sound calibration
% TO 2023/12/07


%% CALIBRATE (optional)
% LOAD BPOD FIRST
% global BpodSystem

%start up HiFi module and set general settings
% needs cleared/restarted HiFi module
SoundCal = SoundCalibration_Manual([19000,20000],500,60,1,-45);

%% save file
file_name =  'SoundCalibration20240118.mat';
file_path = fullfile('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files',file_name);
save(file_path, "SoundCal");
%% plot SoundCal
figure, hold on
plot(SoundCal(1).Table(:,1),SoundCal(1).Table(:,2),'-ok')

%% set HifiPlayer
HiFiPlayer = BpodHiFi('COM9');
HiFiPlayer.SamplingRate = 192000;
HiFiPlayer.DigitalAttenuation_dB = -45; % Set to the same as DetectionConfidence

%% load custom sound calibration file
file_to_use =  'SoundCalibration20240118.mat';
BpodSystem.CalibrationTables.SoundCal = load(fullfile('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files',file_to_use));
BpodSystem.CalibrationTables.SoundCal=BpodSystem.CalibrationTables.SoundCal.SoundCal;
SoundCal = BpodSystem.CalibrationTables.SoundCal;

%% plot calibration functions
figure('Color',[1,1,1])
hold on
plot(SoundCal(1).Table(:, 1),SoundCal(1).Table(:, 2),'-ok')
p = polyfit (SoundCal(1).Table(:, 1),SoundCal(1).Table(:, 2),1);
p_f = @(f) p(1).*f + p(2);
plot(SoundCal(1).Table(:, 1),p_f(SoundCal(1).Table(:, 1)),'-r')
p = polyfit (SoundCal(1).Table(:, 1),SoundCal(1).Table(:, 2),2);
p_f = @(f) p(1).*f.^2 + p(2).*f + p(3);
plot(SoundCal(1).Table(:, 1),p_f(SoundCal(1).Table(:, 1)),'-b')
p = polyfit (SoundCal(1).Table(:, 1),SoundCal(1).Table(:, 2),4);
p_f = @(f) p(1).*f.^4 + p(2).*f.^3 + p(3).*f.^2 + p(4).*f + p(5);
plot(SoundCal(1).Table(:, 1),p_f(SoundCal(1).Table(:, 1)),'-g')
xlabel('Frequency Hz'); ylabel('att factor')
l=legend({'interpolate','linear','polyfit2','polyfit4'})'; l.Box = 'off';

%% Compare 2 Calibration Tables
disp('new round')
file_to_compare1 =  'SoundCalibration.mat';
%file_to_compare2 =  'SoundCalibration20231221digAtt30beforeSF.mat';
%file_to_compare3 =  'SoundCalibration20231221digAttafterSF30.mat';
SoundCal_to_compare1 = load(fullfile('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files',file_to_compare1));
%SoundCal_to_compare2 = load(fullfile('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files\SoundCalibrationBackUp\UltrasonicSpeakers',file_to_compare2));
%SoundCal_to_compare3 = load(fullfile('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files\SoundCalibrationBackUp\UltrasonicSpeakers',file_to_compare3));
figure, hold on
plot(SoundCal(1).Table(:,1),SoundCal.Table(:,2),'-ok') % global HiFiPlayer removed
hold on 
plot(SoundCal_to_compare1.SoundCal.Table(:,1),SoundCal_to_compare1.SoundCal.Table(:,2),'-or') %digAtt set after 30 glabal variables not removed
% hold on
% plot(SoundCal_to_compare2.SoundCal.Table(:,1),SoundCal_to_compare2.SoundCal.Table(:,2),'-og') %digAtt set before sf 30
% hold on
% plot(SoundCal_to_compare3.SoundCal.Table(:,1),SoundCal_to_compare3.SoundCal.Table(:,2),'-om') %digAtt set after sf 30
%saveas(figure, file_to_use, 'png');
%% Run tests
% which calibration methods to test?
% newv ersion of GenerateInterpolatedSignal (backwards compatible) to
% specify which method to use
% test_calbration_methods = {'interpolate','linearfit','polyfit2','polyfit4'};
test_calbration_methods = {'interpolate'};
for k = 1:length(test_calbration_methods)

    %general settings
    StimulusSettings.CalibrationMethod = test_calbration_methods{k}; %NEW calibration method setting
    StimulusSettings.SignalVolume = 60;
    StimulusSettings.SignalDuration = 2;
    StimulusSettings.SamplingRate = 192000;
    StimulusSettings.SignalForm = 'LinearUpsweep';
    StimulusSettings.Ramp = 0.01;
    StimulusSettings.SignalVolume = 60;
    StimulusSettings.MaxVolume = 60;
    StimulusSettings.MinVolume = 60;

    %% pure tone test GenerateSinWave
    for freq = SoundCal.Table(:, 1)'
        sound = GenerateSineWave(StimulusSettings.SamplingRate, freq, StimulusSettings.SignalDuration);
        sound=[sound;sound];
        toneAtt = interp1(SoundCal.Table(:,1), SoundCal.Table(:,2), freq, 'nearest');
        sound(1,:)=sound(1,:).*toneAtt;
        sound(2,:) = 0; %only left speaker playing
        HiFiPlayer.load(1, sound); %only Left
        % HiFi built-in envelope function comes after loading sound
        Envelope = 1/(StimulusSettings.SamplingRate*0.001):1/(StimulusSettings.SamplingRate*0.001):1; % Define 1ms linear ramp envelope of amplitude coefficients, to apply at sound onset + in reverse at sound offset
        HiFiPlayer.AMenvelope = Envelope;
        HiFiPlayer.push();
        disp(strcat("Playing ", num2str(freq),  " Hz"))
        HiFiPlayer.play(1);
        pause(StimulusSettings.SignalDuration)
        pause(1);
    end
    % pure tone test GenerateSinWave without doubling sound
%     for freq = SoundCal.Table(:, 1)'
%         sound = GenerateSineWave(StimulusSettings.SamplingRate, freq, StimulusSettings.SignalDuration);
%         toneAtt = interp1(SoundCal.Table(:,1), SoundCal.Table(:,2), freq, 'nearest');
%         sound(1, :)=sound(1, :).*toneAtt;
%         HiFiPlayer.load(1, sound); %only Left
%         % HiFi built-in envelope function comes after loading sound
%         Envelope = 1/(StimulusSettings.SamplingRate*0.001):1/(StimulusSettings.SamplingRate*0.001):1; % Define 1ms linear ramp envelope of amplitude coefficients, to apply at sound onset + in reverse at sound offset
%         HiFiPlayer.AMenvelope = Envelope;
%         HiFiPlayer.push();
%         disp(strcat("Playing ", num2str(freq),  " Hz"))
%         HiFiPlayer.play(1);
%         pause(StimulusSettings.SignalDuration)
%         pause(1);
%     end
    %% pure tone test Generate interpolated sound
    for freq = SoundCal(1).Table(:, 1)'
        StimulusSettings.SignalMinFreq = freq;
        StimulusSettings.SignalMaxFreq = freq;
        SignalStream = GenerateInterpolatedSignal(StimulusSettings);

        HiFiPlayer.load(2,SignalStream);
        HiFiPlayer.push();
        disp(strcat("Playing ", num2str(freq),  " Hz"))
        HiFiPlayer.play(2);
        pause(StimulusSettings.SignalDuration)
        pause(1);
    end
    
    % pure tone test, shifted
%     pause(5)
%     shift_freq=10;
%     for freq = SoundCal(1).Table(:, 1)'
%         StimulusSettings.SignalMinFreq = freq+shift_freq;
%         StimulusSettings.SignalMaxFreq = freq+shift_freq;
%         SignalStream = GenerateInterpolatedSignal(StimulusSettings);
% 
%         HiFiPlayer.load(2,SignalStream);
%         HiFiPlayer.push();
%         disp(strcat("Playing ", num2str(freq+shift_freq),  " Hz"))
%         HiFiPlayer.play(2);
%         pause( StimulusSettings.SignalDuration)
%         pause(1);
%     end

    %% sweep test
    pause(5)
    StimulusSettings.SignalDuration = 0.1;
    StimulusSettings.SignalMinFreq = 10000;
    StimulusSettings.SignalMaxFreq = 15000;
    %SignalStream = GenerateInterpolatedSignal(StimulusSettings);
    SignalStream = GenerateInterpolatedSignal(StimulusSettings);

    HiFiPlayer.load(3,SignalStream);
    HiFiPlayer.push();
    disp(strcat("Playing upsweep"))
    HiFiPlayer.play(3);
    pause(StimulusSettings.SignalDuration)

    %noise test
    pause(2)
    StimulusSettings.NoiseColor = 'WhiteGaussian';
    StimulusSettings.NoiseDuration = 10;
    StimulusSettings.NoiseVolume = 45;
    StimulusSettings.SignalMinFreq = 10000; %used for att factors
    StimulusSettings.SignalMaxFreq = 15000;
    StimulusSettings.MaxVolume=70;
    StimulusSettings.MinVolume=-20;
    StimulusSettings.RandomStream=rng('shuffle');
    StimulusSettings.RampNoiseBeg = false; %apply ramp at beginning of noise stimulus (signal will always apply)
    StimulusSettings.RampNoiseEnd = true; %apply ramp at beginning of noise stimulus (signal will always apply)
    NoiseStream = GenerateNoise(StimulusSettings);
    mean(abs(NoiseStream(:)))
    HiFiPlayer.load(2,NoiseStream);
    HiFiPlayer.push();
    disp(strcat("Playing noise"))
    HiFiPlayer.play(2);
    pause(StimulusSettings.NoiseDuration)
    pause(10)
end

delete(HiFiPlayer)
clear HiFiPlayer