function [] = convert_emaWav4ag(exptname, subj, wavtrials)
% 
% Script to convert wav files from EMA data collection into a structure that audioGUI can work with
%
% Creates very bare-bones data and expt files. 
% 
% Needs wav files and a list of phrases (CSV) 
% 
% 
% initiated RPK 2024-09-10

dbstop if error

%%

if nargin < 1 || isempty(exptname), exptname = []; end
if nargin < 2 || isempty(subj), subj = []; end


if isempty(exptname) || isempty(subj)
    dataPath = cd; 
    fprintf('Using current folder.\n'); 
    dirParts = strsplit(dataPath, filesep); 

    subj = dirParts{end}; 
    exptName = dirParts{end-2}; 
else
    dataPath = get_kExptLoadPath(exptname, subj); 
end

expt.subj = subj; 
expt.exptName = exptName; 
expt.gender = get_gender; 

%% Load in trial information 

% Trial information 
if exist(fullfile(dataPath, 'trialInfo.csv'))
    trialInfo = readtable(fullfile(dataPath, 'trialInfo.csv')); 
else
    warning('No trial information found for this participant. Returning. \n')
    return; 
end

% Verify trials
if nargin < 3 || isempty(wavtrials)
    wavtrials = 1:height(trialInfo); 
end

if length(wavtrials) ~= height(trialInfo)
    warning('The number of trials in trialInfo and those given to the function do not match.')
    return; 
end

expt.ntrials = length(wavtrials); 

% Get headers from trialInfo
tableVars = trialInfo.Properties.VariableNames; 
fieldsNoTrial = tableVars(~strcmp(tableVars, 'trial')); 

% Make expt-like structure with fields (not including trials) 
for f = 1:length(fieldsNoTrial)
    field = fieldsNoTrial{f}; 
    uniqueField = field; 
    camelField = [upper(field(1)) field(2:end)]; 
    if ~strcmp(field, 'stimulusText')
        uniqueField = [uniqueField 's']; 
        camelField = [camelField 's']; 
    end
    
    % Build fake expt structure
    expt.(uniqueField) = unique([trialInfo.(field)])'; 
    expt.(['list' camelField]) = [trialInfo.(field)]'; 
    for t = 1:length(expt.(['list' camelField]))
        expt.(['all' camelField])(t) = find(strcmp(expt.(['list' camelField])(t), expt.(uniqueField))); 
    end        

end

%% Go through the wavs 

wavDir = fullfile(dataPath, 'wav'); 
params = getAudapterDefaultParams(expt.gender); 
expt.params = params; 

fprintf('Reading in audio data... ')
t = 1; 
for i = wavtrials
    if mod(i, 20)
        fprintf('%d ', i); 
    else
        fprintf('%d\n', i);
    end
    trial = i; 
    trialFilename = [sprintf('%04d', trial) '.wav']; 
    [trialWav, Fs] = audioread(fullfile(wavDir, trialFilename)); 
    trialWav = resample(trialWav, 1, 3); % downsampling... lol

    peak = max(abs(trialWav)); 
    peakFactor = 0.5/peak; 
    data(t).signalIn = trialWav' * peakFactor; 
    
    overSamps = mod(length(trialWav), expt.params.frameLen); 
    if overSamps
        padNans = nan(expt.params.frameLen - overSamps, 1); 
        trialWav = [trialWav; padNans]; 
    end
    % Make a matrix with one frame per row and one sample per column
    rmsdata = reshape(trialWav, [], expt.params.frameLen); % 96 samples per RMS frame 'cause audapter standards.
    data(t).rms = rms(rmsdata, 2)'; % Calculates one RMS value per row 

    data(t).params = params; 

    t = t+1; 
end

expt.fs = Fs; 

%% Save

fprintf('\nSaving expt.mat... ')
save(fullfile(dataPath, 'expt.mat'), 'expt'); 
fprintf('Done.\n')

fprintf('Saving data.mat... ')
save(fullfile(dataPath, 'data.mat'), 'data'); 
fprintf('Done.\n')



end