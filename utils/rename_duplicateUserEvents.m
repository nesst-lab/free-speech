function [] = rename_duplicateUserEvents(dataPath, trials, uevName)
%
%

dbstop if error

%% 

if nargin < 1 || isempty(dataPath), dataPath = cd; end


%%
segmentFolder = 'trials'; 
segmentFolderContents = dir(fullfile(dataPath, segmentFolder)); 
segmentFiles = {segmentFolderContents.name}; 
segmentFiles = segmentFiles(contains(segmentFiles, '.mat')); 

splitSegmentFiles = split(segmentFiles, '.mat'); 
segmentNumbers = splitSegmentFiles(:, :, 1); 
segmentNumbers = cellfun(@str2double, segmentNumbers); 

if nargin < 2 || isempty(trials), trials = segmentNumbers; end

%% Load in expt

fprintf('Renaming event names... '); 
it = 0; 
for t = trials
    it = it + 1; 
    trialFile = sprintf('%d.mat', t); 
    load(fullfile(dataPath, segmentFolder, trialFile)); 
    uevNames = trialparams.event_params.user_event_names; 

    definedUevNames = uevNames(~cellfun(@isempty, uevNames)); 
    uniqueUevNames = unique(definedUevNames); 

    if length(uniqueUevNames) == length(uevNames)
        print_locationInLoop(sprintf('(not %d)', t), 25, it); 
        continue; 
    else
        print_locationInLoop(sprintf('%d', t), 25, it); 
        for i = 1:length(uniqueUevNames)
            uniqueUev = uniqueUevNames{i}; 
            dupUevIx = sort(find(strcmp(uevNames, uniqueUev))); 

            if length(dupUevIx) > 1
                for d = 1:length(dupUevIx)
                    dIx = dupUevIx(d); 
                    uevNames{dIx} = sprintf('%s%d', uevNames{dIx}, d); 
                end
            end
        end
    end

    trialparams.event_params.user_event_names = uevNames; 

    save(fullfile(dataPath, segmentFolder, trialFile), 'sigmat', 'trialparams'); 

    clear sigmat
    clear trialparams

end

fprintf('\nDone.\n'); 





end % EOF 