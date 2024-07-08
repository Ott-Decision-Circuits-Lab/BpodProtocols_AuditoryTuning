SoundCal = SoundCalibration_Manual_Modified([1000 20000], 20, 60, 1);

FOR PLOTTING ATTENUATION FACTORS, INTERPOLATION AND POLYVAL LINE
figure
plot(SoundCal(1).Table(:,1), SoundCal(1).Table(:,2), 'o')
hold on
line = polyval(SoundCal(1).Coefficient ,1:20000);
plot(line);
xlabel("Hz")
ylabel("Attenuation factor")
a = gca;
a.XAxis.Exponent = 0;
a.YAxis.Exponent = 0;
x = SoundCal(1).Table(:,1);
v = SoundCal(1).Table(:,2);
%xq = linspace(SignalMinFreq,SignalMaxFreq,SamplingRate*SignalDuration);
xq = linspace(1000,20000,192000*0.1);
vq = interp1(x,v,xq);
plot(xq, vq);
legend("Actual", "Fitted", "Interpolated");
%title("Rig 2 Jan 29 90 degrees MONO, dig att -45")
title("Tabletop Feb 11th 0 degrees MONO, dig att -40")
axis([0 20000 0 1])



FOR PLAYING UPSWEEP AND NOISE

StimulusSettings.SamplingRate=192000;%sampling rate of sound card
StimulusSettings.Ramp=.05;%duration (s) of ramping at on and offset of noise used to avoid clicking sounds
StimulusSettings.RampNoiseBeg = false; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.RampNoiseEnd = true; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.NoiseDuration=5;%length of noise stream (s) (no loop so make sure)
StimulusSettings.NoiseColor='WhiteGaussian';
StimulusSettings.MaxVolume=70;
StimulusSettings.MinVolume=-20;
StimulusSettings.SignalForm='LinearUpsweep';
StimulusSettings.SignalDuration=0.6;
StimulusSettings.SignalVolume = 60;
StimulusSettings.SignalMinFreq=10000;
StimulusSettings.SignalMaxFreq=15000;
StimulusSettings.RandomStream=rng('shuffle');
StimulusSettings.NoiseVolume = 45;

NoiseStream = GenerateNoise(StimulusSettings);
SignalStream = GenerateInterpolatedSignal(StimulusSettings).*1;

sf=StimulusSettings.SamplingRate;
td = BpodSystem.Data.Custom.TrialData.PreStimDuration(iTrial);
Spad=zeros(size(NoiseStream));
Spad(:,ceil(td*sf):(ceil(td*sf)+size(SignalStream,2)-1))=SignalStream;
NplusS = NoiseStream + Spad;
HiFiPlayer.load(2,NplusS);
HiFiPlayer.push();
HiFiPlayer.play(2);

FOR PLAYING NOISE ONLY

H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
StimulusSettings.SamplingRate=192000;%sampling rate of sound card
StimulusSettings.Ramp=.05;%duration (s) of ramping at on and offset of noise used to avoid clicking sounds
StimulusSettings.RampNoiseBeg = false; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.RampNoiseEnd = true; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.NoiseDuration=4;%length of noise stream (s) (no loop so make sure)
StimulusSettings.NoiseColor='WhiteGaussian';
StimulusSettings.MaxVolume=70;
StimulusSettings.MinVolume=-20;
StimulusSettings.SignalForm='LinearUpsweep';
StimulusSettings.SignalDuration=3;
StimulusSettings.SignalVolume = 60;
StimulusSettings.SignalMinFreq=500;
StimulusSettings.SignalMaxFreq=20000;
StimulusSettings.RandomStream=rng('shuffle');
StimulusSettings.NoiseVolume = 40;
NoiseStream = GenerateNoise(StimulusSettings);
H.load(2,NoiseStream);
H.push();
H.play(2);

StimulusSettings.RandomStream=rng('shuffle');
for noiseVolume = [70; 65; 60; 55; 50; 45; 40; 35]'
StimulusSettings.NoiseVolume = noiseVolume;
NoiseStream = GenerateNoise(StimulusSettings);
H.load(2,NoiseStream);
H.push();
disp(strcat("Playing ", num2str(noiseVolume),  " dB noise")) 
H.play(2);
pause(4);
end

FOR SINGLE PLAYING PURE TONE FROM PREPARESTIMULUS.M WITH GENERATEINTERPOLATEDSIGNAL.M

StimulusSettings.SignalVolume = 60;
StimulusSettings.SignalDuration = 3
StimulusFreq = 1000;
StimulusSettings.SignalMinFreq = StimulusFreq;
StimulusSettings.SignalMaxFreq = StimulusFreq;
SignalStream = GenerateInterpolatedSignal(StimulusSettings).*1;
HiFiPlayer.load(2,SignalStream);
HiFiPlayer.push();
HiFiPlayer.play(2);

FOR TESTING GENERATEINTERPOLATEDSIGNAL.M BY ITSELF
addpath('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Protocols\DetectionConfidence')
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
H.SamplingRate = 192000;
H.DigitalAttenuation_dB = -45; % Ensure this is set to the same as in DetectionConfidence.m
StimulusSettings.SamplingRate=192000;%sampling rate of sound card
StimulusSettings.Ramp=.05;%duration (s) of ramping at on and offset of noise used to avoid clicking sounds
StimulusSettings.RampNoiseBeg = false; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.RampNoiseEnd = true; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.NoiseColor='WhiteGaussian';
StimulusSettings.MaxVolume=75;
StimulusSettings.MinVolume=-20;
StimulusSettings.SignalForm='LinearUpsweep';
StimulusSettings.SignalDuration = 3;
StimulusSettings.SignalVolume = 60;
StimulusSettings.NoiseDuration=4;
StimulusSettings.NoiseVolume = 40;

for freq = SoundCal(1).Table(:, 1)'
StimulusSettings.SignalMinFreq = freq;
StimulusSettings.SignalMaxFreq = freq;
SignalStream = GenerateInterpolatedSignal(StimulusSettings).*1;
pause(3);
H.load(2,SignalStream);
H.push();
disp(strcat("Playing ", num2str(freq),  " Hz"))
H.play(2);
end

StimulusSettings.SignalVolume = 75;
for freq = SoundCal(1).Table(:, 1)'
StimulusSettings.SignalMinFreq = freq;
StimulusSettings.SignalMaxFreq = freq;
SignalStream = GenerateInterpolatedSignal(StimulusSettings).*1;
pause(3);
H.load(2,SignalStream);
H.push();
disp(strcat("Playing ", num2str(freq),  " Hz"))
H.play(2);
end

FOR PLAYING UPSWEEPS OF DIFFERENT DURATIONS
%H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
%H.SamplingRate = 192000;
%H.DigitalAttenuation_dB = -50; % Ensure this is set to the same as in DetectionConfidence.m
StimulusSettings.SamplingRate=192000;%sampling rate of sound card
StimulusSettings.Ramp=.05;%duration (s) of ramping at on and offset of noise used to avoid clicking sounds
StimulusSettings.RampNoiseBeg = false; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.RampNoiseEnd = true; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.NoiseDuration=4;%length of noise stream (s) (no loop so make sure)
StimulusSettings.NoiseColor='WhiteGaussian';
StimulusSettings.MaxVolume=70;
StimulusSettings.MinVolume=-20;
StimulusSettings.SignalForm='LinearUpsweep';
StimulusSettings.SignalVolume = 60;
StimulusSettings.SignalMinFreq = 10000;
StimulusSettings.SignalMaxFreq = 25000;

for signalDuration = [0.1; 0.2; 0.3; 1; 3; 5; 10; 15]'
StimulusSettings.SignalDuration= signalDuration;
SignalStream = GenerateInterpolatedSignal(StimulusSettings).*1;
H.load(2,SignalStream);
H.push();
if signalDuration < 1
pause(1)
else
pause(signalDuration)
end
disp(strcat("Playing upsweep of duration ", num2str(signalDuration ),  "s"))
H.play(2);
end


BAR PLOT FOR 20 FREQUENCIES

bar(1:20, [63.6, 67.2, 66.4, 65.9, 65.2, 64.9, 66.3, 65.9, 65.2, 59.3, 57.8, 65.1, 61.7, 60.2, 56, 61.4, 63.5, 53.7, 69.8, 48.3]-60)
xlabel("Hz")
ylabel("dB error")
xticks(1:20)
xticklabels(round(SoundCal(1).Table(:, 1), 0))
ylim([-20, 15])
title("Rig 3, Nov 21th, calibration with 20 frequencies, 1-20 kHz, both speakers, target 60 dB, sounds made with GenerateSineWave.m")

FOR LOOPING THROUGH PURE TONES USING GENERATESINEWAVE.m (L SPEAKER)

H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1)
for i=1:length(SoundCal(1).Table(:, 1))
TestWave = GenerateSineWave(192000, SoundCal(1).Table(i, 1), 3) * SoundCal(1).Table(i, 2);
H.load(1, [TestWave; zeros(1,length(TestWave))]); H.push; H.play(1);
pause(3);
end

FOR PLAYING SINGLE FREQUENCIES WITH GENERATESINEWAVE.M (L SPEAKER)
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1)
freq = 1000
TestWave = GenerateSineWave(192000, freq, 3) * SoundCal(1).Table(1, 2);
H.load(1, [zeros(1,length(TestWave)); TestWave]); H.push; H.play(1);


FOR PLAYING PURE TONES USING GENERATESINEWAVE.m (R SPEAKER)

H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1)
for i=1:length(SoundCal(2).Table(:, 1))
TestWave = GenerateSineWave(192000, SoundCal(2).Table(i, 1), 3) * SoundCal(2).Table(i, 2);
H.load(1, [zeros(1,length(TestWave)); TestWave]); H.push; H.play(1);
pause(3);
end

FOR PLAYING PURE TONES USING GENERATESINEWAVE.m (BOTH SPEAKERS)

H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1)
samplingRate = 192000;
signalDuration = 3;
for i=1:length(SoundCal(1).Table(:, 1))
frequency = SoundCal(1).Table(i, 1);
attenFactL = SoundCal(1).Table(i, 2);
attenFactR = SoundCal(2).Table(i, 2);
TestWaveL = GenerateSineWave(samplingRate, frequency, signalDuration) * attenFactL;
TestWaveR = GenerateSineWave(samplingRate, frequency, signalDuration) * attenFactR;
disp(strcat("Playing ", num2str(frequency), " Hz"));
H.load(1, [TestWaveL; TestWaveR]); H.push; H.play(1);
pause(3);
end

FOR PLAYING PURE TONES USING GENERATESINEWAVE.m (ONE SPEAKER)
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1)
samplingRate = 192000;
signalDuration = 3;
for i=1:length(SoundCal(1).Table(:, 1))
frequency = SoundCal(1).T able(i, 1);
attenFactL = SoundCal(1).Table(i, 2);
attenFactR = SoundCal(2).Table(i, 2);
TestWaveL = GenerateSineWave(samplingRate, frequency, signalDuration) * attenFactL;
TestWaveR = GenerateSineWave(samplingRate, frequency, signalDuration) * attenFactR;
noSound = zeros(1,length(TestWaveL));
disp(strcat("Playing ", num2str(frequency), " Hz"));
H.load(1, [TestWaveL; noSound]); H.push; H.play(1);
pause(3);
end


FOR TESTING WITH SOUNDCARD USING GENERATESINEWAVE.M

SOUND AT 50% volume
freq - attFactor
500 - 0.0072
1000 - 0.0015
1500 - 0.003
2000 - 0.0045
2500 - 0.00057
3000 - 0.0006
3500 - 0.001
4000 - 0.00045
4500 - 0.00098
5000 - 0.00047

freqs = [500:500:5000];
attFactors = [0.0072, 0.0015, 0.003, 0.0045, 0.00057, 0.0006, 0.001, 0.00045, 0.00098, 0.00047];
for i=1:length(freqs)
freq = freqs(i);
attFactor = attFactors(i);
sound(GenerateSineWave(192000, freq, 3)*attFactor, 192000);
disp(strcat("Playing ", num2str(freq), " Hz"))
pause(4);
end

FOR PLAYING ENDLESS LOOP WITH GENERATEINTERPOLATEDSIGNAL
load('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Calibration Files\SoundCalibration.mat')
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
H.DigitalAttenuation_dB = -45
StimulusSettings.SamplingRate=192000;%sampling rate of sound card
StimulusSettings.Ramp=.05;%duration (s) of ramping at on and offset of noise used to avoid clicking sounds
StimulusSettings.RampNoiseBeg = false; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.RampNoiseEnd = true; %apply ramp at beginning of noise stimulus (signal will always apply)
StimulusSettings.NoiseDuration=4;%length of noise stream (s) (no loop so make sure)
StimulusSettings.NoiseColor='WhiteGaussian';
StimulusSettings.MaxVolume=75;
StimulusSettings.MinVolume=-20;
StimulusSettings.SignalForm='LinearUpsweep';
StimulusSettings.SignalDuration=3;
StimulusSettings.SignalVolume = 60;
while true
for freq = SoundCal(1).Table(:, 1)'
StimulusSettings.SignalMinFreq = freq;
StimulusSettings.SignalMaxFreq = freq;
SignalStream = GenerateInterpolatedSignal(StimulusSettings).*1;
pause(3);
H.load(2,SignalStream);
H.push();
disp(strcat("Playing ", num2str(freq),  " Hz"))
H.play(2);
if freq == SoundCal(1).Table(end, 1)
pause(4)
end
end
end

FOR NATURAL TESTING INSIDE DETECTIONCONFIDENCE

StimulusSettings.SamplingRate=192000;
StimulusSettings.Ramp=.05;
StimulusSettings.RampNoiseBeg = false;
StimulusSettings.RampNoiseEnd = true;
StimulusSettings.NoiseColor='WhiteGaussian';
StimulusSettings.MaxVolume=70;
StimulusSettings.MinVolume=-20;
StimulusSettings.SignalForm='LinearUpsweep';
StimulusSettings.SignalDuration=0.6;
StimulusSettings.SignalVolume = 60;
StimulusSettings.SignalMinFreq=10000;
StimulusSettings.SignalMaxFreq=15000;
StimulusSettings.RandomStream=rng('shuffle');
StimulusSettings.NoiseVolume = 40;
StimulusSettings.NoiseDuration=4;

NoiseStream = GenerateNoise(StimulusSettings);
SignalStream = GenerateInterpolatedSignal(StimulusSettings).*1;

sf=StimulusSettings.SamplingRate;
td = BpodSystem.Data.Custom.TrialData.PreStimDuration(iTrial);
Spad=zeros(size(NoiseStream));
Spad(:,ceil(td*sf):(ceil(td*sf)+size(SignalStream,2)-1))=SignalStream;
NplusS = NoiseStream + Spad;
HiFiPlayer.load(2,NplusS);
HiFiPlayer.push();
HiFiPlayer.play(2);

FOR NATURAL TESTING INSIDE DETECTIONCONFIDENCE - LOOPS
addpath('C:\Users\BasicTraining\Documents\MATLAB\Bpod Local\Protocols\DetectionConfidence')
HiFiPlayer = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
HiFiPlayer.DigitalAttenuation_dB = -45

StimulusSettings.SamplingRate=192000;
StimulusSettings.Ramp=.05;
StimulusSettings.RampNoiseBeg = false;
StimulusSettings.RampNoiseEnd = true;
StimulusSettings.NoiseColor='WhiteGaussian';
StimulusSettings.MaxVolume=90;
StimulusSettings.MinVolume=-20;
StimulusSettings.SignalForm='LinearUpsweep';
StimulusSettings.SignalDuration=5;
StimulusSettings.SignalMinFreq=10000;
StimulusSettings.SignalMaxFreq=15000;
StimulusSettings.NoiseDuration=4;

%2nd run of testing only use part below without redifining BpodHiFi
for signalVol = [45; 50; 55; 60; 65; 70; 75; 80]'
StimulusSettings.RandomStream=rng('shuffle');
StimulusSettings.SignalVolume = signalVol;
SignalStream = GenerateInterpolatedSignal(StimulusSettings).*1;
HiFiPlayer.load(2,SignalStream);
HiFiPlayer.push();
disp(strcat("Playing ", num2str(signalVol),  " db"))
HiFiPlayer.play(2);
pause(2)
end

for noiseVol = [45; 50; 55; 60]'
StimulusSettings.RandomStream=rng('shuffle');
StimulusSettings.NoiseVolume = noiseVol;
NoiseStream = GenerateNoise(StimulusSettings);
HiFiPlayer.load(2,NoiseStream);
HiFiPlayer.push();
disp(strcat("Playing ", num2str(noiseVol),  " db"))
HiFiPlayer.play(2);
pause(4)
end

HiFiPlayer.delete
clear HiFiPlayer

