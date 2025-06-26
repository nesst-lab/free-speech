function [errorTrials] = gen_timingDataVals(dataPath, buffertype, bSave)
%
% Largely copied from gen_dataVals_tramTransfer. This is the generic function that will simply get the start times and
% duration of every segment in STIMULUS TEXT. 
% 
% All segment start times are stored as segmentStart_time, e.g. ehStart_time
% 
% All segment durations are stored as segmentDur, e.g., ehDur
%  
% Initiated RK 2025/06/26 

dbstop if error 

%%
if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(buffertype), buffertype = 'signalIn'; end

% set output files
if strcmp(buffertype, 'signalIn')
    trialDir = 'trials';
else
    trialDir = 'trials_signalOut'; 
end
savefile = fullfile(dataPath,['dataVals_' buffertype '.mat']);

if nargin < 3 || isempty(bSave), bSave = savecheck(savefile); end

if ~bSave
    warning('Can''t save to expected location (%s). Ending script.', savefile);
    return; 
end

% load expt files
load(fullfile(dataPath,'expt.mat'), 'expt');
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'));
else
    sigproc_params = get_sigproc_defaults;
end
trialPath = fullfile(dataPath,trialDir); % e.g. trials; trials_default
[sortedTrialnums,sortedFilenames] = get_sortedTrials(trialPath); % these should be the same for both in/out so only need to define once
dataVals = struct([]);

for i = 1:length(expt.words)
    word = expt.words{i}; 
    ix.(word) = find(expt.allWords == i); 
end

%% Get all unique arpabet strings 

for s = 1:length(expt.stimulusText)
    stimulusText = expt.stimulusText{s}; 
    splitStim = split(stimulusText, ' '); % Split by spaces into cells so you can string together the whole tihng
    trialPhrase = []; 
    
    % go through each word and get the arpabet for it 
    for s = 1:length(splitStim)
        stimPart = splitStim{s}; 
        arpaStimPart = word2arpabet(stimPart); 
        if length(arpaStimPart) > 1
            questionText = warning('There are multiple versions of this word ("%s"): ', stimPart); 
            for a = 1:length(arpaStimPart)
                versionText = [fprintf('Version %d: ', a) fprintf('%s ', arpaStimPart{a}{1:end}) fprintf('\n')]; 
            end
            whichOne = askNChoiceQuestion('Which one would you like to use?', [1:length(arpaStimPart)]); 
        else
            whichOne = 1; 
        end
        
        arpaStimPart = arpaStimPart{whichOne}; 
        trialPhrase = [trialPhrase arpaStimPart]; 
    end



%% Extract data from each trial

e = 1; % error trial counter
errorTrials = []; 
fprintf('Generating dataVals for %s... ', buffertype)
bSkip = 0; 
for i = 1:length(sortedTrialnums)
    trialnum = sortedTrialnums(i);
    filename = sortedFilenames{i};
    print_locationInLoop(trialnum, 25, i); 
    
    
        

    if exist(fullfile(trialPath, filename), 'file')
        load(fullfile(trialPath,filename)); 
    
        % get user-created events
        if exist('trialparams','var') ...
                && isfield(trialparams,'event_params') ...
                && ~isempty(trialparams.event_params)
            user_event_times = trialparams.event_params.user_event_times;
            user_event_names = trialparams.event_params.user_event_names; 
        else
            user_event_times = [];
            user_event_names = {}; 
            warning('No events for trial %d\n',trialnum); 
        end
        n_events = length(user_event_times);
        bSkip = 0; 
    else
        bSkip = 1; 
    end

    if trialparams.event_params.is_good_trial && ~bSkip
        if strcmp(expt.listWords{trialnum}, word1)
            onset_time = user_event_times(strcmp(user_event_names,word1Upper(1)));
        elseif strcmp(expt.listWords{trialnum}, word2)
            onset_time = user_event_times(strcmp(user_event_names,word2Upper(1)));
        end

        % event times
        vStart_time = user_event_times(strcmp(user_event_names,'AH') | strcmp(user_event_names,'EH'));        
        sStart_time = user_event_times(strcmp(user_event_names,'S')); 
        cStart_time = user_event_times(strcmp(user_event_names,word1Upper(end)));
        cBurst_time = user_event_times(find(strcmp(user_event_names,word1Upper(end)) + 1)); 

        % segment durations
        onsDur = vStart_time - onset_time; 
        vDur = sStart_time - vStart_time; 
        sDur = cStart_time - sStart_time; 
        cDur = cBurst_time - cStart_time; 

        % Get the lengthening and shortening targets 
        lengthenTargetDur = vDur;         

        if n_events > max_events
            warning('%d events found in trial %d (expected %d)',n_events,trialnum,max_events);
            fprintf('ignoring event %d\n',max_events+1:n_events)
        elseif n_events < max_events
            warning('Only %d events found in trial %d (expected %d)',n_events,trialnum,max_events);
            fprintf('Check for empty values.\n')
            errorTrials(e) = trialnum; 
            e = e+1; 
        end

        dataVals(i).onset_time = onset_time;            
        dataVals(i).vStart_time = vStart_time; 
        dataVals(i).sStart_time = sStart_time; 
        dataVals(i).cStart_time = cStart_time;
        dataVals(i).cBurst_time = cBurst_time;

        dataVals(i).onsDur = onsDur;
        dataVals(i).vDur = vDur; 
        dataVals(i).sDur = sDur; 
        dataVals(i).cDur = cDur; 

        dataVals(i).dur = sStart_time - vStart_time; % for dataVals tracking. this is only the stressed vowel dur
        dataVals(i).wordDur = cBurst_time - vStart_time;    
        dataVals(i).lengthenTargetDur = lengthenTargetDur;

        dataVals(i).wordList = expt.listWords(trialnum);
        dataVals(i).condList = expt.listConds(trialnum);
        dataVals(i).word = expt.allWords(trialnum); 
        dataVals(i).cond = expt.allConds(trialnum); 
        dataVals(i).trial = trialnum; % Trial number
        dataVals(i).token = find(trialnum == ix.(expt.listWords{trialnum})); % repetition of that specific word 
        if expt.pertMag(trialnum) > 0
            dataVals(i).bPerturb = 1;
        else
            dataVals(i).bPerturb = 0; 
        end
            

    else % bad and non-existent trials get all NaNs
        dataVals(i).onset_time = NaN;
        dataVals(i).vStart_time = NaN; 
        dataVals(i).sStart_time = NaN; 
        dataVals(i).cStart_time = NaN; 
        dataVals(i).cBurst_time = NaN;

        dataVals(i).dur = NaN; % for dataVals tracking. this is only the stressed vowel dur
        dataVals(i).wordDur = NaN; 
        dataVals(i).onsDur = NaN;
        dataVals(i).vDur = NaN; 
        dataVals(i).sDur = NaN; 
        dataVals(i).cDur = NaN; 
        dataVals(i).lengthenTargetDur = NaN;

        dataVals(i).wordList = expt.listWords(trialnum);
        dataVals(i).condList = expt.listConds(trialnum);
        dataVals(i).word = expt.allWords(trialnum); 
        dataVals(i).cond = expt.allConds(trialnum); 
        dataVals(i).trial = trialnum; 
        dataVals(i).token = find(trialnum == ix.(expt.listWords{trialnum}));
        if expt.pertMag(trialnum) > 0
            dataVals(i).bPerturb = 1;
        else
            dataVals(i).bPerturb = 0; 
        end


    end
    if exist('trialparams','var') && isfield(trialparams,'event_params') && ~isempty(trialparams.event_params)
        dataVals(i).bExcl = ~trialparams.event_params.is_good_trial;
    else
        dataVals(i).bExcl = 0;
    end
end

%% Save the dataVals

save(savefile,'dataVals');
fprintf('%d trials saved in %s.\n',length(sortedTrialnums),savefile);

end
