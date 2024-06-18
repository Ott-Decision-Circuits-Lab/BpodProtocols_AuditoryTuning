

    %general settings
HiFiPlayer = BpodHiFi('COM9');
HiFiPlayer.SamplingRate = 192000;
HiFiPlayer.DigitalAttenuation_dB = -35; % Set to the same as DetectionConfidence



    StimulusSettings.SignalVolume = 60;
    StimulusSettings.SamplingRate = 192000;
    StimulusSettings.DigitalAttenuation_dB = -35; % Set to the same as DetectionConfidence
    StimulusSettings.SignalForm = 'LinearUpsweep';
    StimulusSettings.Ramp = 0.01;
    StimulusSettings.SignalVolume = 60;
    StimulusSettings.MaxVolume = 60;
    StimulusSettings.MinVolume = 60;
    StimulusSettings.SignalDuration = 20;
    StimulusSettings.SignalMinFreq = 500;
    StimulusSettings.SignalMaxFreq = 10000;
    SignalStream = GenerateInterpolatedSignal(StimulusSettings);

    HiFiPlayer.load(2,SignalStream);
    HiFiPlayer.push();
    disp(strcat("Playing upsweep"))
    HiFiPlayer.play(2);
    pause(StimulusSettings.SignalDuration)
 