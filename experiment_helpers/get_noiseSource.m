function [w] = get_noiseSource(p, noiseName)
%GET_NOISESOURCE  Get Audapter-playable noise from file.
%   GET_NOISESOURCE(NOISEWAVFN,P) loads an audio file from NOISEWAVFN and,
%   if necessary, resamples it to the recording rate specified in the
%   Audapter parameter struct P, and truncates it to the maximum playback
%   length allowed by Audapter.

if nargin < 2 || isempty(noiseName)
    noiseName = 'mtbabble48k.wav'; % RK addition for using a dumb way of making a metronome + noise in audapter 
end

audapterDir = fileparts(which('AudapterIO'));
noiseWavFN = fullfile(audapterDir,noiseName);
check_file(noiseWavFN);
[w, fs] = read_audio(noiseWavFN);
if fs ~= p.sr * p.downFact    % resample noise to recording rate
    w = resample(w, p.sr * p.downFact, fs);              
end
maxPBSize = Audapter('getMaxPBLen');
if length(w) > maxPBSize
    w = w(1 : maxPBSize);
end