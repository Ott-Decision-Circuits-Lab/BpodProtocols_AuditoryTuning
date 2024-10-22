function [noise] =GenerateNoise(StimulusSettings)
global BpodSystem %we need this for volume adjustment

%% abbreviate variable names and clip impossible values for better handling
SamplingRate=StimulusSettings.SamplingRate;
Ramp=StimulusSettings.Ramp;
NoiseColor=StimulusSettings.NoiseColor;
NoiseDuration=StimulusSettings.NoiseDuration;
NoiseVolume=max(min(StimulusSettings.NoiseVolume,StimulusSettings.MaxVolume),StimulusSettings.MinVolume);%clip noise volume to Min and Max
SignalMinFreq=StimulusSettings.SignalMinFreq;
SignalMaxFreq=StimulusSettings.SignalMaxFreq;
RandomStream=StimulusSettings.RandomStream;

%% generate noise
%set random number generator to given state and seed (to ensure
%reproducibility)
rng(RandomStream);

%generate noise vector
samplenum=round(SamplingRate * NoiseDuration);
switch NoiseColor
    case 'WhiteUniform'
        noise = 2 * rand(1, samplenum) - 1;%make white uniform noise -1 to 1
    case 'WhiteGaussian' %gaussian noise from mean 0 std .25
        noise = .25 * randn(1, samplenum);%make white gausian noise and clip to [-1 1]
        noise(noise<-1)=-1;
        noise(noise>1)=1;
    case 'PinkGaussian'
        noise = f_alpha_gaussian (samplenum,.2^2,1)';%make colored gaussian noise with std .2 and 1/f^alpha
        %     case 'naturalistic' %https://www.ncbi.nlm.nih.gov/pubmed/18301738 "Efficient coding of naturalistic stimuli"
        %         noise = randn(1, samplenum);%
        %         noise1 = f_alpha_gaussian ( samplenum,1, 0.1)';%make colored noise  1/f^alpha
        %         noise2 = f_alpha_gaussian ( samplenum,1, 0.1)';%make colored noise 1/f^alpha
        %         noisemodulator=(noise1.^2+noise2.^2).^.1;%make colored noise modulator with amplitude modulation spectrume Raleigh
end

%clip noise to [-1 1]
noise(noise<-1)=-1;
noise(noise>1)=1;

%put in double speaker
noise = [noise;noise];

%adjust noise volume
SoundCal = BpodSystem.CalibrationTables.SoundCal;
nocal=false;
if(isempty(SoundCal))
    disp('Error: no sound calibration file specified');
     nocal=true;
%     return
end
% if size(SoundCal,2)<2
%    disp('Error: no two speaker sound calibration file specified');
%     nocal=true;
% %    return
% end
%for s=1:2 %loop over two speakers
    if nocal
        toneAtt = 0.5;
        diffSPL = NoiseVolume - 60;
    else
        toneAtt = mean(SoundCal.Table(:, 2)); %just take the mean over all signal frequencies
        %use mean of attenuation factors in frequency range
        %toneAtt = mean(SoundCal(1,s).Table(SoundCal(1,s).Table(:,1)>=SignalMinFreq&SoundCal(1,s).Table(:,1)<=SignalMaxFreq,2));
        diffSPL = NoiseVolume - [SoundCal.TargetSPL] + 9;
    end
    %toneAtt = [polyval(SoundCal(1,1).Coefficient,toneFreq)' polyval(SoundCal(1,2).Coefficient,toneFreq)']; in Torben's script
    attFactor = sqrt(10.^(diffSPL./10)); %sqrt(10.^(diffSPL./10)) in Torben's script WHY sqrt?
    att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
    noise(1,:)=noise(1,:).*att; %should the two speakers dB be added?
%end

noise(2, :) = zeros(1, length(noise)); % For playing only L channel (MONO)

%put an envelope to avoide clicking sounds at beginning and end
omega=(acos(sqrt(0.1))-acos(sqrt(0.9)))/(Ramp/pi*2); % This is for the envelope with Ramp duration duration
t=0 : (1/SamplingRate) : pi/2/omega;
t=t(1:(end-1));
RaiseVec= (cos(omega*t)).^2;

Envelope = ones(length(noise),1); % This is the envelope
if StimulusSettings.RampNoiseBeg
    Envelope(1:length(RaiseVec)) = fliplr(RaiseVec);
end
if StimulusSettings.RampNoiseEnd
    Envelope(end-length(RaiseVec)+1:end) = (RaiseVec);
end

noise = noise.*Envelope';