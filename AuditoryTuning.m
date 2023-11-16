%{
----------------------------------------------------------------------------

This file is part of the Sanworks Bpod repository
Copyright (C) 2022 Sanworks LLC, Rochester, New York, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings

    S.GUI.SoundDuration = 0.2; % Duration of sound (s)
    S.GUI.ITI = 1; % Seconds after stimulus sampling for a response
    S.GUI.TrialsPerCondition = 10;
    S.GUI.NoiseSound = 0; % if 1, plays a white noise pulse on error. if 0, no sound is played.
    S.GUIMeta.NoiseSound.Style = 'checkbox';

    S.GUI.MinFreq = 500; % Frequency of left cue
    S.GUI.MaxFreq = 20000; % Frequency of right cue
    S.GUI.StepFreq = 500;

    S.GUI.MinVolume = 60; 
    S.GUI.MaxVolume = 60;
    S.GUI.StepVolume = 10;

    S.GUIPanels.Sound = {'SoundDuration', 'ITI', 'TrialsPerCondition','NoiseSound'};
    S.GUIPanels.Freq = {'MinFreq','MaxFreq','StepFreq'};
    S.GUIPanels.Volume = {'MinVolume','MaxVolume','StepVolume'};
end

%% Define trials
FreqVector = S.GUI.MinFreq:S.GUI.StepFreq:S.GUI.MaxFreq;
FreqTrials_single = repmat(FreqVector,1,S.GUI.TrialsPerCondition);

VolVector = S.GUI.MinVolume:S.GUI.StepVolume:S.GUI.MaxVolume;
FreqTrials = repmat(FreqTrials_single,1,length(VolVector));

VolTrials = VolVector'*ones(1,length(FreqTrials_single));
VolTrials=VolTrials';
VolTrials = VolTrials(:)';

MaxTrials = length(FreqTrials);

BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.

%% Initialize plots
BpodParameterGUI('init', S); % Initialize parameter GUI plugin

%% Define stimuli and send to analog module
SF = 192000; % Use max supported sampling rate
H.SamplingRate = SF;

% White Noise trials might be added 
NoiseSound = GenerateWhiteNoise(SF, S.GUI.SoundDuration, 1, 2);

H.DigitalAttenuation_dB = -15; % Set a comfortable listening level for most headphones (useful during protocol dev).

Envelope = 1/(SF*0.001):1/(SF*0.001):1; % Define 1ms linear ramp envelope of amplitude coefficients, to apply at sound onset + in reverse at sound offset
H.AMenvelope = Envelope;


%% Main trial loop
for iTrial = 1:MaxTrials

    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin

    %% abbreviate variable names and clip impossible values for better handling
    StimulusSettings.SamplingRate = SF;
    StimulusSettings.Ramp = 0.01; %UPDATE HERE IF NO NOISE IS USED
    StimulusSettings.SignalDuration = S.GUI.SoundDuration;
    StimulusSettings.SignalForm = 'LinearUpsweep';
    StimulusSettings.SignalMinFreq = FreqTrials(iTrial);
    StimulusSettings.SignalMaxFreq = FreqTrials(iTrial);
    StimulusSettings.SignalVolume = VolTrials(iTrial);

    sound = GenerateSignal(StimulusSettings);
    
    H.load(1, sound);
    H.load(2, NoiseSound);
    
    sma = NewStateMatrix(); % Assemble state matrix
    
    sma = AddState(sma,'Name','Initialize', ...
        'Timer',0.1,...
        'StateChangeConditions',{'Tup','PlaySound'}, ...
        'OutputAction',{'HiFi1','*'});

    sma = AddState(sma, 'Name', 'PlaySound', ...
        'Timer', S.GUI.SoundDuration,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'HiFi1', ['P', 0]}); %

    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', S.GUI.ITI,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {}); %TO DO: output action should be silence

    SendStateMachine(sma); % Send the state matrix to the Bpod device
    RawEvents = RunStateMachine; % Run the trial and return events
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned (i.e. if not final trial, interrupted by user)
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        %BpodSystem.Data.TrialSettings(iTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        %BpodSystem.Data.TrialTypes(iTrial) = TrialTypes(iTrial); % Adds the trial type of the current trial to data
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.Status.BeingUsed == 0 % If protocol was stopped, exit the loop
        return
    end

end