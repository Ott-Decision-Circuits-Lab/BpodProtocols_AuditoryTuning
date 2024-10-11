%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2022 Sanworks LLC, Rochester, New York, USA

----------------------------------------------------------------------------

Authors: Dariya Kassybayeva, Torben Ott
Description:
Modified Bpod script that allows to play pure tones of frequencies in a
specified range, repeated TrialsPerCondition repetition for each frequency.
Volume can also be adjusted and same wavelength could be played in
different volumes. 
Example: frequencies will be played from 500 Hz to 20 000 Hz in steps of
500 Hz with signal lasting 0.2 sec and intertrial interval of 1 sec. This
sequence will be repeated 10 times to yield 10 repetitions per each
frequency. Volume is set as a constant to 60 dB. This results in 40
frequencies per each run and 400 trials overall. If different set of
volumes is to be played, the number of the trials will increase with 10
repetitions of each frequency and each volume pair. 
Modified: 2024-08-15 17:06

%}
function AuditoryTuning
% This protocol demonstrates a 2AFC task using the HiFi module to generate sound stimuli.
% Subjects initialize each trial with a poke into port 2. After a delay, a tone plays.
% If subjects exit the port before the tone is finished playing, a dissonant error sound is played.
% Subjects are rewarded for responding left for low-pitch tones, and right for high.
% A white noise pulse indicates incorrect choice.
% A TTL pulse is delivered from BNC output CH1 with the tone stimulus. This is
% useful for viewing stimulus onset latency (e.g. on an oscilloscope).
% A 1ms linear ramp envelope is applied to the stimulus at onset and offset
% (even when offset is triggered by the test subject). See 'H.AMenvelope'
% below to configure a custom envelope, or to disable it by setting to [].

global BpodSystem

%
% SETUP
% You will need:
% - A Bpod state machine v0.7+
% - A Bpod HiFi module, loaded with BpodHiFiPlayer firmware.
% - Connect the HiFi module's State Machine port to the Bpod state machine
% - From the Bpod console, pair the HiFi module with its USB serial port.
% - Connect channel 1 (or ch1+2) of the hifi module to an amplified speaker(s).

%% Assert HiFi module is present + USB-paired (via USB button on console GUI)
BpodSystem.assertModule('HiFi', 1); % The second argument (1) indicates that the HiFi module must be paired with its USB serial port
% Create an instance of the HiFi module
H = BpodHiFi(BpodSystem.ModuleUSB.HiFi1); % The argument is the name of the HiFi module's USB serial port (e.g. COM3)

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
%if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings

S.GUI.SoundDuration = 0.05; % Duration of sound (s) > 50 ms TODO to be added into values in bpod file saved
S.GUI.ITI = TruncatedExponential(0.8, 1.2, 1); % Seconds after stimulus sampling for a response 0.8-1.5 sec TruncExp
S.GUI.ITIPause1 = TruncatedExponential(0.8, 1.2, 1); %between pure tone and upsweep
S.GUI.ITIPause2 = TruncatedExponential(0.8, 1.2, 1); %between upsweep and noise

S.GUI.TrialsPerCondition = 5;
S.GUI.NoiseSound = 1; % if 1, plays a white noise pulse on error. if 0, no sound is played.
S.GUIMeta.NoiseSound.Style = 'checkbox';

S.GUI.MinFreq = 1000; % Frequency of left cue
S.GUI.MaxFreq = 20000; % Frequency of right cue
S.GUI.StepFreq = 500;
S.GUI.BorderStepFreq = 1000;

S.GUI.MinVolume = 70;
S.GUI.MaxVolume = 70;
S.GUI.StepVolume = 10;

S.GUIPanels.Sound = {'SoundDuration', 'ITI', 'TrialsPerCondition','NoiseSound'};
S.GUIPanels.Freq = {'MinFreq','MaxFreq','StepFreq'};
S.GUIPanels.Volume = {'MinVolume','MaxVolume','StepVolume'};
%end

%% Define trials
% Define which frequencies to play
FreqVectorBeg = S.GUI.MinFreq:S.GUI.BorderStepFreq:9000;
FreqVectorMid = 9000:S.GUI.StepFreq:16000; 
FreqVectorEnd = 16000:S.GUI.BorderStepFreq:20000;
FreqVector = [FreqVectorBeg, FreqVectorMid, FreqVectorEnd];
% FreqVector is repeated so that each frequency gets several plays with
% same exact settings (to account for variability in neural responses to the same stimuli)
FreqTrials_single = repmat(FreqVector,1,S.GUI.TrialsPerCondition); 
% Randomize the order in which these pure tones are played
FreqTrials_single = FreqTrials_single(randperm(length(FreqTrials_single))); %randomize the order of frequencies once they are repeated 

VolVector = S.GUI.MinVolume:S.GUI.StepVolume:S.GUI.MaxVolume;
FreqTrials = repmat(FreqTrials_single,1,length(VolVector));

VolTrials = VolVector'*ones(1,length(FreqTrials_single)); %if 2 volumes in VolumeVector, FreqTrials double
VolTrials=VolTrials';
VolTrials = VolTrials(:)';

MaxTrials = length(FreqTrials);

BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.Custom.Frequency = [];
BpodSystem.Data.Custom.Volume = [];

%% Initialize plots
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%% Define stimuli and send to analog module
SF = 192000; % Use max supported sampling rate
H.SamplingRate = SF;
H.DigitalAttenuation_dB = -10; % Set a comfortable listening level for most headphones (useful during protocol dev).

%Load SoundCal table
SoundCal = BpodSystem.CalibrationTables.SoundCal;
nocal=false;

%% Main trial loop
for iTrial = 1:MaxTrials

    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin

    %% abbreviate variable names and clip impossible values for better handling
    StimulusSettings.SamplingRate = SF;
    StimulusSettings.Ramp = 0.001; %UPDATE HERE IF NO NOISE IS USED
    StimulusSettings.SignalDuration = S.GUI.SoundDuration;
    StimulusSettings.SignalForm = 'LinearUpsweep';
    StimulusSettings.SignalMinFreq = 10000;
    StimulusSettings.SignalMaxFreq = 15000;
    StimulusSettings.SignalVolume = VolTrials(iTrial);
    StimulusSettings.ITI = S.GUI.ITI;

    %% Generate pure tone signal
    sound = GenerateSineWave(SF, FreqTrials(iTrial), S.GUI.SoundDuration);
    sound=[sound;sound];

    %% Generate Upsweeps signal
    % GenerateSineSweep(samplingRate, startFreq, endFreq, duration)
    %UpsweepSound = GenerateSineSweep(SF, 10000, 15000, S.GUI.SoundDuration);
    %UpsweepSound = [UpsweepSound; UpsweepSound];
    UpsweepSound = GenerateInterpolatedSignal(StimulusSettings);

    %% Generate noise signal
    NoiseSound = GenerateWhiteNoise(SF, S.GUI.SoundDuration, 1, 1);
    %NoiseSound = [NoiseSound; NoiseSound];

    %Error message if SoundCal table doesn't exist
    if(isempty(SoundCal))
        disp('Error: no sound calibration file specified. Sound not calibrated.');
        nocal=true;
    end
    %Error message if SoundCal table doesn't include two speakers
    if size(SoundCal,2)>2
        disp('Error: more than one speaker sound calibration file specified. Sound not calibrated.');
        nocal=true;
    end

    if nocal == false
        %toneAtt = SoundCal(1,s).Coefficient; % basic implementation with auto generated cooeficient based on polyval of all attFactors for all freq > inaccurate
        idx_toneAtt =  find(round(SoundCal.Table(:,1))==FreqTrials(iTrial));
        if ~isempty(idx_toneAtt)
            %if SoundCal has exact freq needed
            idx_toneAtt =  find(round(SoundCal.Table(:,1))==FreqTrials(iTrial));
            %closest_freq = interp1(SoundCal(s).Table(:,1), SoundCal(s).Table(:,1), FreqTrials(iTrial), 'nearest');
            toneAtt = SoundCal.Table(idx_toneAtt, 2);
        else
            %disp("SoundCalibration is not using precise frequencies used in this protocol.");
            %if SoundCal was calibrated in a range with equally spaced freqs
            %d=sort(abs(FreqTrials(iTrial)-SoundCal(s).Table(:,1)));
            %closest=find(abs(FreqTrials(iTrial)-SoundCal(s).Table(:,1))==d(1));
            %sec_closest=find(abs(FreqTrials(iTrial)-SoundCal(s).Table(:,1))==d(2));

            %freqVec = [SoundCal(s).Table(closest,1), SoundCal(s).Table(sec_closest,1)];
            %toneAttVec = [SoundCal(s).Table(closest,2), SoundCal(s).Table(sec_closest,2)];

            %toneAtt = interp1(freqVec, toneAttVec, FreqTrials(iTrial));
            toneAtt = interp1(SoundCal.Table(:,1), SoundCal.Table(:,2), FreqTrials(iTrial), 'nearest');
            disp("Interpolation")
            if isnan(toneAtt)
                fprintf("Error: Test frequency %d Hz is outside calibration range.\n", FreqTrials(iTrial));
                return
            end
        end
    else
        disp("Error: no sound calibration.");
        return
    end
    sound(1,:)=sound(1,:).*toneAtt;

    % For playing only L or R channel when signal=[signal;signal];
    sound(2, :) = zeros(1, length(sound)); % For playing only L channel
    %signal(1, :) = zeros(1, length(signal)); % For playing only R channel
  
    %% 
    % Use these 2 lines if not using GenerateInterpolatedSound
    %UpsweepSound(1,:)=UpsweepSound(1,:).*toneAtt;
    %UpsweepSound(2, :) = zeros(1, length(UpsweepSound)); % For playing only L channel
    NoiseSound(:)=NoiseSound(:).*toneAtt;
    %% GenerateSignal Script using upsweeps instead
    %sound = GenerateSignal(StimulusSettings);

    %% Manual envelope should come before loading
    % GenerateSinWave includes envelope functions,
    % GenerateInterpolatedSignal will require manual envelope inside the function

    %% Load sound to HiFi
    H.load(1, sound);
    disp("Sound");
    H.load(2, UpsweepSound) % plays upsweeps and noise between every pure tone
    disp("Upsweep")
    H.load(3, NoiseSound);
    disp("Noise")

    %% HiFi built-in envelope function comes after loading sound
    Envelope = 1/(SF*0.001):1/(SF*0.001):1; % Define 1ms linear ramp envelope of amplitude coefficients, to apply at sound onset + in reverse at sound offset
    H.AMenvelope = Envelope;

    %% load sounds that already include an Envelope after
    % H.load(2, UpsweepSound)
    % H.load(3, NoiseSound);

    sma = NewStateMatrix(); % Assemble state matrix

%     sma = AddState(sma,'Name','Initialize', ...
%         'Timer',0.1,...
%         'StateChangeConditions',{'Tup','PlaySound'}, ...
%         'OutputAction',{'HiFi1','*'});
% 
%     sma = AddState(sma, 'Name', 'PlaySound', ...
%         'Timer', S.GUI.SoundDuration,...
%         'StateChangeConditions', {'Tup', 'ITI'},...
%         'OutputActions', {'HiFi1', ['P', 0]}); %
% 
%     sma = AddState(sma, 'Name', 'ITI', ...
%         'Timer', S.GUI.ITI,...
%         'StateChangeConditions', {'Tup', 'exit'},...
%         'OutputActions', {}); %TO DO: output action should be silence

    %% New States
    sma = AddState(sma,'Name','Initialize', ...
        'Timer',0.1,...
        'StateChangeConditions',{'Tup','PlaySound'}, ...
        'OutputAction',{'HiFi1','*'});

    sma = AddState(sma, 'Name', 'PlaySound', ...
        'Timer', S.GUI.SoundDuration,...
        'StateChangeConditions', {'Tup', 'ITIPause1'},...
        'OutputActions', {'HiFi1', ['P', 0]}); % Play pure tone on channel 1
    
    sma = AddState(sma, 'Name', 'ITIPause1', ...
        'Timer', S.GUI.ITIPause1,...
        'StateChangeConditions', {'Tup', 'PlayUpsweep'},...
        'OutputActions', {});

    sma = AddState(sma, 'Name', 'PlayUpsweep', ...
        'Timer', S.GUI.SoundDuration,... % Adjust duration as needed
        'StateChangeConditions', {'Tup', 'ITIPause2'},...
        'OutputActions', {'HiFi1', ['P', 1]}); % Play upsweep on channel 2

    sma = AddState(sma, 'Name', 'ITIPause2', ...
        'Timer', S.GUI.ITIPause2,...
        'StateChangeConditions', {'Tup', 'PlayNoise'},...
        'OutputActions', {});

    sma = AddState(sma, 'Name', 'PlayNoise', ...
        'Timer', S.GUI.SoundDuration,... % Adjust duration as needed
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'HiFi1', ['P', 2]}); % Play noise on channel 3
    

    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', S.GUI.ITI,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});

    SendStateMachine(sma); % Send the state matrix to the Bpod device
    RawEvents = RunStateMachine; % Run the trial and return events
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned (i.e. if not final trial, interrupted by user)
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.Custom.Frequency(iTrial) = FreqTrials(iTrial);
        BpodSystem.Data.Custom.Volume(iTrial) = VolTrials(iTrial);
        %BpodSystem.Data.TrialSettings(iTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        %BpodSystem.Data.TrialTypes(iTrial) = TrialTypes(iTrial); % Adds the trial type of the current trial to data
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    S.GUI.ITI = TruncatedExponential(0.8, 1.5, 1); % Seconds after stimulus sampling for a response 0.8-1.5 sec TruncExp
    S.GUI.ITIPause1 = TruncatedExponential(0.8, 1.5, 1); %between pure tone and upsweep
    S.GUI.ITIPause2 = TruncatedExponential(0.8, 1.5, 1); %between upsweep and noise
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if iTrial == MaxTrials
        BpodSystem.Status.BeingUsed = 0;
    end
    if BpodSystem.Status.BeingUsed == 0 % If protocol was stopped, exit the loop
        return
    end
end
disp("Task finished")