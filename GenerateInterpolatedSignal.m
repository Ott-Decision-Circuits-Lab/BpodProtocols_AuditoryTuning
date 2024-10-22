function signal=GenerateInterpolatedSignal(StimulusSettings)

global BpodSystem %we need this for volume adjustment

%% abbreviate variable names and clip impossible values for better handling
SamplingRate=StimulusSettings.SamplingRate;
SignalRamp=StimulusSettings.Ramp; %UPDATE HERE IF NO NOISE IS USED
SignalDuration=StimulusSettings.SignalDuration;
SignalForm=StimulusSettings.SignalForm;
SignalMinFreq=StimulusSettings.SignalMinFreq;
SignalMaxFreq=StimulusSettings.SignalMaxFreq;
%SignalVolume=max(min(StimulusSettings.SignalVolume,StimulusSettings.MaxVolume),StimulusSettings.MinVolume);%clip signal volume to Min and Max
SignalVolume = StimulusSettings.SignalVolume;
    
    t=linspace(0, SignalDuration, SamplingRate*SignalDuration); %time vector for chirp, linspace(x1,x2,n) generates n points. The spacing between the points is (x2-x1)/(n-1). n =960 000
    switch SignalForm
        case 'LinearUpsweep'
            signal=chirp(t, SignalMinFreq, SignalDuration, SignalMaxFreq); %where t timepoints adjusted with Sampling Rate
            freqvec=SignalMinFreq+(SignalMaxFreq-SignalMinFreq)*t;
        case 'LinearDownsweep' %gaussian noise from mean 0 std .25
            signal=chirp(t,SignalMaxFreq,SignalDuration,SignalMinFreq);
            freqvec=SignalMaxFreq+(SignalMinFreq-SignalMaxFreq)*t;
        case 'QuadraticConvex'
            tnew=t-mean(t);
            signal=chirp(tnew,SignalMinFreq,SignalDuration./2,SignalMaxFreq,'quadratic',[],'convex'); %make chirp
            freqvec=SignalMinFreq+(SignalMaxFreq-SignalMinFreq)./tnew(1)*tnew.^2;
    end
    
    signal=[signal;signal];
    
    %adjust signal volume
    SoundCal = BpodSystem.CalibrationTables.SoundCal;
    nocal=false;
    if(isempty(SoundCal)) 
        disp('Error: no sound calibration file specified. Sound not  calibrated.');
        nocal=true;
%         return
    end
%     if size(SoundCal,2)<2
%         disp('Error: no two speaker sound calibration file specified. Sound not  calibrated.');
%         nocal=true;
% %         return
%     end
    
    %for s=1:2 %loop over two speakers
        if nocal
            toneAtt = 0.5*ones(size(freqvec));
            diffSPL = SignalVolume - 60;
        else
            %toneAtt = polyval(SoundCal(1,s).Coefficient,freqvec);%Frequency dependent attenuation factor with less attenuation for higher frequency (based on calibration polynomial)
            %toneAtt = [polyval(SoundCal(1,1).Coefficient,toneFreq)' polyval(SoundCal(1,2).Coefficient,toneFreq)']; in Torben's script
            
            % Interpolate frequency-dependent attenuation factors
            x = SoundCal.Table(:,1);
            v = SoundCal.Table(:,2);
            xq = linspace(SignalMinFreq,SignalMaxFreq,SamplingRate*SignalDuration); % continious values from 10kHz to 15kHz
            vq = interp1(x,v,xq);
            %vq = pchip(x,v,xq);
            toneAtt = vq;

            % MANUALLY ADJUST SIGNAL VOLUME DISCREPANCIES
            diffSPL = SignalVolume - [SoundCal.TargetSPL]; % This line assumes the calculation works (for most signal volumes, it doesn't)
            if SignalVolume > 75
                diffSPL = SignalVolume - [SoundCal.TargetSPL] - 0; % Loud sounds are usually too quiet
            elseif SignalVolume > 70
                diffSPL = SignalVolume - [SoundCal.TargetSPL] - 0;
            elseif SignalVolume > 45 && SignalVolume <= 70
                diffSPL = SignalVolume - [SoundCal.TargetSPL] - 0;
            elseif SignalVolume >= 35 && SignalVolume <= 45
                diffSPL = SignalVolume - [SoundCal.TargetSPL] - 0; % Quiet sounds are usually too loud
            end
        end
        
        attFactor = sqrt(10.^(diffSPL./10)); %sqrt(10.^(diffSPL./10)) in Torben's script WHY sqrt?
        att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
        signal(1,:)=signal(1,:).*att; %should the two speakers dB be added?
    %end

% For playing only L or R channel when signal=[signal;signal];
signal(2, :) = zeros(1, length(signal)); % For playing only L channel
%signal(1, :) = zeros(1, length(signal)); % For playing only R channel

%put an envelope to avoide clicking sounds at beginning and end
%The Envelope is commentted for  AuditoryTuning, it already has an
%envelope and Ramp 0.001
omega=(acos(sqrt(0.1))-acos(sqrt(0.9)))/(SignalRamp/pi*2); % This is for the envelope with Ramp duration duration
t=0 : (1/SamplingRate) : pi/2/omega;
t=t(1:(end-1));
RaiseVec= (cos(omega*t)).^2;

Envelope = ones(length(signal),1); % This is the envelope
Envelope(1:length(RaiseVec)) = fliplr(RaiseVec);
Envelope(end-length(RaiseVec)+1:end) = (RaiseVec);

signal = signal.*Envelope';
