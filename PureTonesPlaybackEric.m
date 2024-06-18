%For Testing SoundCalibration 
%Notice this script does not include Envelope or Ramp
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1);
samplingRate = 192000;
signalDuration = 3;
SoundCal = BpodSystem.CalibrationTables.SoundCal;
nocal=false;
for i=1:length(SoundCal(1).Table(:, 1))
frequency = SoundCal(1).Table(i, 1);
attenFactL = SoundCal(1).Table(i, 2);
attenFactR = SoundCal(2).Table(i, 2);
TestWaveL = GenerateSineWave(samplingRate, frequency, signalDuration) * attenFactL;
TestWaveR = GenerateSineWave(samplingRate, frequency, signalDuration) * attenFactR;
noSound = zeros(1,length(TestWaveL));
disp(strcat("Playing ", num2str(frequency), " Hz"));
H.load(1, [TestWaveL; noSound]); H.push; H.play(1); % Alternate for L vs R
%H.load(1, [noSound; TestWaveR]); H.push; H.play(1);
pause(3);
end