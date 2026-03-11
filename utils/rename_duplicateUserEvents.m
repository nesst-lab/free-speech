function [] = rename_duplicateUserEvents(dataPath, trials, uevName2Change)
% A function to rename any duplicately named user events. Made specifically for deftAcoustic, which has multiple B's. Setting
% signal out user events relies on unique names. 
% 
% This may also be helpful for anything that uses check_timingDataVals, which also does better with unique names. 
% 
% Recommend that this be done between hand-correction and setting signal out user events. Currently this will only work on
% signalIn, but can be modified to do signalOut as well. 
% 
% INPUTS
% 
%   dataPath                the path for where the data are---should be the file that contains the trials folder. defaults to
%                           current working directory. 
% 
%   trials                  the trials you want to change names on. Defaults to all trials contained in the trials folder. 
%                           Should be a vector. Note: the loop will skip over any trials that don't have duplicates, so you
%                           can specify the whole experiment even if you've already done a subpart, or if some of them don't
%                           have duplicates. 
% 
%   uevNames                a cell array of user event names that you want to change. For example, if you only want to do the
%                           B's but not D's in "buy dougie a buddy", you can specify {'B'}. 
% 
% No outputs. Saves into trial file. 
% 
% RK and MR initiated 2026-03-11. Tested on deftAcoustic data
% 


dbstop if error

%% 

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin == 3 % transition into cell if not already 
    if ~iscell(uevName2Change), uevName2Change = {uevName2Change}; end
end

%% Get list of trials
segmentFolder = 'trials'; 
segmentFolderContents = dir(fullfile(dataPath, segmentFolder)); 
segmentFiles = {segmentFolderContents.name}; 
segmentFiles = segmentFiles(contains(segmentFiles, '.mat')); 

splitSegmentFiles = split(segmentFiles, '.mat'); 
segmentNumbers = splitSegmentFiles(:, :, 1); 
segmentNumbers = cellfun(@str2double, segmentNumbers); 

% Set default
if nargin < 2 || isempty(trials) 
    trials = segmentNumbers; 
else 
    if length(trials) > length(segmentNumbers)
        warning('More trials are requested than are segmented. Only changing UEVs for trials that have been segmented.')
        trials = trials(ismember(trials, segmentNumbers)); 
    end
end
trials = sort(trials); 

%% Load in expt

fprintf('Renaming event names... '); 
it = 0; 
for t = trials
    it = it + 1; % iteration variable for printing
    trialFile = sprintf('%d.mat', t); 
    load(fullfile(dataPath, segmentFolder, trialFile)); 
    uevNames = trialparams.event_params.user_event_names; 

    definedUevNames = uevNames(~cellfun(@isempty, uevNames)); % this gets rid of the blank events at the beginning/end
    uniqueUevNames = unique(definedUevNames); % this gets the unique items 

    % Check which event names you actually want to change 
    if nargin < 3 || isempty(uevName2Change)
        uevName2Change = uniqueUevNames; % Because of the way we're doing it, you just want to use all of the existing UEVs if unspecified        
    end

    if length(uniqueUevNames) == length(uevNames)
        % If you only have unique event names, skip
        print_locationInLoop(sprintf('(not %d)', t), 25, it); 
        continue; 
    else
        % If there are duplicates
        print_locationInLoop(sprintf('%d', t), 25, it); 

        % Loop through all the unique UEV names
        for i = 1:length(uniqueUevNames)
            uniqueUev = uniqueUevNames{i}; 
            dupUevIx = sort(find(strcmp(uevNames, uniqueUev))); % check if there are multiple of them 

            % If there are duplicates
            if length(dupUevIx) > 1 && ismember(uniqueUev, uevName2Change) % AND you're working with a thing you want to change
                % Loop over those indices
                for d = 1:length(dupUevIx)
                    dIx = dupUevIx(d); 
                    uevNames{dIx} = sprintf('%s%d', uevNames{dIx}, d); % Change them to, e.g., B1 B2 B3
                end
            end
        end
    end

    % Put the new information into trialparams
    trialparams.event_params.user_event_names = uevNames; 

    % Save
    save(fullfile(dataPath, segmentFolder, trialFile), 'sigmat', 'trialparams'); 

    % clear vars
    clear sigmat
    clear trialparams

end

fprintf('\nDone.\n'); 





end % EOF 