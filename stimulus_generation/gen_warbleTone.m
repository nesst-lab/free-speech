function [warbleTone] = gen_warbleTone(saveDir, baseFreq, warbleFreq, stimDur, steadyFactor, fs, bPlay, bSave)
% Function to generate warble tones 
% 
% INPUTS
%   saveDir             Where you want to save, if bSave = 1. Defaults to pwd. 
%
%   baseFreq            the frequency (in Hz) that you want the warble tone to oscillate around. Defaults to 1000 Hz. You can
%                       put in a vector here, e.g. [500 600 700]
%   
%   warbleFreq          the frequency (in Hz) that you want the tone to warble. Defaults to 5 Hz. 
% 
%   stimDur             the duration of the stimulus, in seconds. Defaults to 0.5 seconds. 
% 
%   steadyFactor        How steady do you want the warble to be? Affects the magnitude of the time warping. 1000 will give
%                       you an extremely stable tone; 1 will give you a very warbly tone. 
% 
%   fs                  Sampling rate of the sound. Defaults to 48000
% 
%   bPlay               If you want to hear the sound when you're playing. If ANY of the baseFreq, warbleFreq, dramaFactor
%                       are vectors, then will default to 0. If you put in 1 it will just ask you if you want to play them
%                       first or not 
% 
%   bSave               If you want to save the resulting tones. Defaults to 1
% 

%
% 
% OUTPUTS 
% 
%   warbleTone          a vector that is a sine wave of varying frequency. This will either save or not depending on bSave
% 
% 
% Method: this function uses a WARPED TIME VECTOR. That is, instead of the time axis being evenly spaced from one sample to
% the next, the distance between time points varies according to warbFreq and dramaFactor. 

%%

dbstop if error

if nargin < 1 || isempty(saveDir), saveDir = pwd; end
if nargin < 2 || isempty(baseFreq), baseFreq = 1000; end
if nargin < 3 || isempty(warbleFreq), warbleFreq = 5; end
if nargin < 4 || isempty(stimDur), stimDur = 0.5; end
if nargin < 5 || isempty(steadyFactor), steadyFactor = 100; end
if nargin < 6 || isempty(fs), fs = 48000; end
if nargin < 7 || isempty(bPlay)
    if length(baseFreq) > 1 || length(warbleFreq) > 1 || length(dramaFator) > 1
        bPlay = 0; 
    else
        bPlay = 1; 
    end
end
if nargin < 8 || isempty(bSave), bSave = 1; end

%% Generate the time axes 

timeAx = 0:1/fs:stimDur-(1/fs); % this makes an evenly spaced vector from 1 to the length of your stimulus, spaced out by the amount of time between samples
warbleWarp = sin(2*pi*warbleFreq*timeAx); % This makes a SINE WAVE using the values from your time axis. 

warbleDiffs = diff([warbleWarp warbleWarp(end)]); % This gets the difference between adjacent items in the warp. 
zeroedWarbleDiffs = warbleDiffs - min(warbleDiffs); % This zeroes them out so that the minimum is 0. Never going BACK in time, always forward. 

timeAxDiffs = diff([timeAx timeAx(end)]); % This is the difference between adjacent items in the plain time axis
timeAxDiffs(end) = timeAxDiffs(1); % so there's not a 0 at the very end. 

warpedTimeAxDiffs = timeAxDiffs + zeroedWarbleDiffs/steadyFactor; % This adds sine-varying amounts of time to the time axis differences
% So now some time differences are very large and some are smaller
warpedTimeAx = cumsum(warpedTimeAxDiffs); % This takes all the differences and makes an always increasing vector using the differences

warpedTimeAx = warpedTimeAx / (max(warpedTimeAx)/stimDur); % This norms it back to the actual duration that you're going for 
%% Make the warble

for f = 1:length(baseFreq)
    warbleTone(f,:) = sin(2*pi*baseFreq(f)*warpedTimeAx); 
    if bPlay
        soundsc(warbleTone(f,:), fs); 
    end

    if bSave
        fileName = sprintf('%dHz_%dHzWarble_%dDrama.wav', baseFreq, warbleFreq, steadyFactor); 
        audiowrite(fullfile(saveDir, fileName), warbleTone(f,:), fs); 
    end
end



%%