function [] = gen_phoneTierFromUevs(dataPath, trials, updatedDirName)
% Function to make new phone-only textgrid from audioGUI user events
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
if ~exist(fullfile(dataPath, updatedDirName))
    mkdir(fullfile(dataPath, updatedDirName)); 
end

trialDir = fullfile(dataPath, 'trials'); 
mfaDir = fullfile(dataPath, 'PostAlignment'); 
correctedDir = fullfile(dataPath, updatedDirName); 

%%
fprintf('Saving phone-only TGs... '); 
for i = trials
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

    % Double check that you have a seg tier and a word tier 
    ntiers = length(tg.tier); 
    if ntiers < 2 
        warning('The textgrid for trial %d does not have enough tiers. Skipping.', i); 
        continue; 
    end

    phoneTier = tg.tier{1,2}; 
    tier2name = phoneTier.name; 

    if ~strcmp(tier2name, 'phones')
        warning('The textgrid for trial %d is not set up like MFA. Skipping.', i); 
        continue; 
    end
    
    % Get the words out of the word tier
    phones = phoneTier.Label(find(~cellfun(@isempty, phoneTier.Label)));
    user_event_names = trialparams.event_params.user_event_names; 
    % emptyUevs = find(cellfun(@isempty, user_event_names));
    % nonemptyUevs = find(~cellfun(@isempty, user_event_names)); 
    nUevs = length(user_event_names); 
    phoneIx = 2:nUevs; 
    user_event_names = user_event_names(phoneIx); % The very first interval is silence, and the last is "empty" because it's just an ending
    if length(phones) ~= length(user_event_names) - 1
        warning('There may have been an error in hand-correction in trial %d', i); 
    end
  
    user_event_times = trialparams.event_params.user_event_times(phoneIx);    

    % Make new structure for the new textgrid based on UEVs
    newPhonesTier.name = 'phones'; 
    newPhonesTier.type = 'interval'; 
    newPhonesTier.T1 = [tg.tmin user_event_times]; 
    newPhonesTier.T2 = [user_event_times tg.tmax]; 
    newPhonesTier.Label = [{''} user_event_names {''}]; 

    % Last stuff out of text grids 
    newTg.tier{1,1} = newPhonesTier; 
    newTg.tmin = tg.tmin; 
    newTg.tmax = tg.tmax; 
    
    tgWrite(newTg, fullfile(correctedDir, tgName)); 
    
end 
    
fprintf('Done.\n')
    


end % EOF 