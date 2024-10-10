function [] = updateTgs(dataPath, trials, updatedDirName)
% Function to make updated copies of TextGrids (as generated from MFA), using hand-corrected boundaries from audioGUI
% 
% Inputs
%   dataPath                the directory that contains: 
%                               - a PostAlignment folder with TextGrids from MFA
%                               - a trials folder that has all of the audioGUI trial.mat files 
%                               - expt.mat 
%                           this directory is also where the new PostCorrection folder will go. Defaults to cd
% 
%   trials                  which trials you want to update. Defaults to 1:expt.ntrials
% 
%   updatedDir              the name of the folder where you want to put the updated textgrids. This will be in a folder
%                           within dataPath. Defaults to PostCorrection
% 
% Outputs
%   [no output]             saved AudioData_[trial].TextGrid files in PostCorrection
%   
% Inititated 2024-10-09 by RPK for timeZapperTP

dbstop if error

%% Set defaults
if nargin < 1 || isempty(dataPath), dataPath = cd; end

load(fullfile(dataPath, 'expt.mat')); 
if nargin < 2 || isempty(trials), trials = 1:expt.ntrials; end

if nargin < 3 || isempty(updatedDirName), updatedDirName = 'PostCorrection'; end
if ~exists(fullfile(dataPath, updatedDirName))
    mkdir(fullfile(dataPath, updatedDirName)); 
end

trialDir = fullfile(dataPath, 'trials'); 
mfaDir = fullfile(dataPath, 'PostAlignment'); 
correctedDir = fullfile(dataPath, updatedDirName); 

%%

for i = 1:trials
    % Load in trial file 
    try
        load(fullfile(trialDir, [num2str(i) '.mat'])); 
    catch
        warning('No audioGUI trial file for trial %d. Skipping.', i); 
        continue; 
    end
    
    % Open the corresponding TG file from PostAlignment 
    try 
        tgName = ['AudioData_' num2str(i) '.TextGrid']; 
        [tg, ~] = tgRead(fullfile(mfaDir, tgName)); 
    catch
        warning('No MF-aligned text grid for trial %d. Skipping.', i); 
        continue; 
    end
    
    % Get information from the word tier (always Tier 1)
    wordStarts = tg.tier{1,1}.T1; 
    corr_wordStarts = wordStarts; 
    corr_wordEnds = tg.tier{1,1}.T2; 
    
    wordLabels = tg.tier{1,1}.Label; 
    wordIntervals = find(~cellfun(@isempty, wordLabels)); % This gets you the labeled intervals (words, not silence)
    blankWords = find(cellfun(@isempty, wordLabels)); 
    word1_start = tg.tier{1,1}.T1(wordIntervals(1));
    word2_start = tg.tier{1,1}.T1(wordIntervals(2)); 
    word2_end = tg.tier{1,1}.T2(wordIntervals(2)); 
    
    % Get information from the seg tier (always Tier 2) 
    segStarts = tg.tier{1,2}.T1; 
    corr_segStarts = NaN(1, length(segStarts)); 
    
    segLabels = tg.tier{1,2}.Label;     
    blankSegs = find(cellfun(@isempty, segLabels));  
    word1_seg1_ix = find(segStarts == word1_start); 
    word2_seg1_ix = find(segStarts == word2_start); 
    word2_seg9_ix = find(segStarts == word2_end); 
    
    % Get empty segment intervals (that aren't first and last) 
    nSegs = length(segStarts); 
    
    % Now go through all of the segments and update them
    user_event_times = trialparams.event_params.user_event_times; 
    user_event_names = trialparams.event_params.user_event_names; 
    
    bExtraBlanks = 0; 
    % Plug in the corrected times 
    for u = 1:length(user_event_times)-1
        user_event_name = user_event_names{u}; 
        segLabel = segLabels{u};         
        
        if strcmp(user_event_name, segLabel)
            corr_segStarts(u) = user_event_times(u);             
            
        else
            % Don't change from NaN
            bExtraBlanks = bExtraBlanks + 1; 
        end
        
    end
    % The T2 will have to come from the last event
    last_segEnd = user_event_times(end); 
    
    % Write the corrected times into the tg    
    tg.tier{1,2}.T1 = corr_segStarts; 
    
    for s = 1:length(corr_segStarts)-1
        tg.tier{1,2}.T2(s) = corr_segStarts(s+1); 
    end
    tg.tier{1,2}.T2(s+1) = last_segEnd; 
    
    % Now correct... the word boundaries... 
    corr_wordStarts(wordIntervals(1)) = corr_segStarts(word1_seg1_ix); 
    corr_wordStarts(wordIntervals(2)) = corr_segStarts(word2_seg1_ix); 
    corr_wordStarts(wordIntervals(2) + 1) = corr_segStarts(word2_seg9_ix); 
    
    for w = 1:length(corr_wordEnds)-1
        corr_wordEnds(w) = corr_wordStarts(w+1); 
    end
    % Last one is already in 
    tg.tier{1,1}.T2 = corr_wordEnds; 
    
    tgWrite(tg, fullfile(correctedDir, tgName)); 
    
end 
    
    









end % EOF 