function [errorTrials] = gen_timingDataVals(dataPath,buffertype,bSave,textField,seg_list)
%
% Largely copied from gen_dataVals_tramTransfer. This is the generic function that will simply get the start times and
% duration of segments labeled by user events. It assumes that all labeled user events are fair game. This works best with
% MFA-aligned data. 
% 
% INPUTS
% 
%       dataPath                the folder where the trial and trials_signalOut folders are that have 1.mat, etc. Defaults to
%                               pwd. Also needs an expt.mat
% 
%       buffertype              signalIn or signalOut. Defaults to signalIn
% 
%       bSave                   a check for whether or not you will save (overwrite!). If not specified, will perform a check
%                               for the existence of a dataVals file; if one already exists then it will ask you want to
%                               overwrite. 
% 
%       textField               the field in expt that has the text that was used for labeling. Defaults to simulusText. 
% 
%       seg_list                the list of segments that you actually want to get information for. Defaults to all. 
% 
% OUTPUTS
% 
%       dataVals                either dataVals_signalIn.mat or dataVals_signalOut.mat is saved. Fields: 
%                                   - segDur: all segments from seg_list will have a field called segDur (e.g., eDur, cDur).
%                                   This is the duration of the interval between the user event labeled as such and the next
%                                   user event 
%                                   - segStart_time: all segments from seg_list will have a field called segStart_time (e.g.,
%                                   eStart_time, cStart_time). This is the time of the user event with that label 
%                                   - trial: the trial number
%                                   - token: the repetition for that specific word/phrase 
%                                   - wordList: the text of what was said (from expt.listWords) 
%                                   - condList: the condition for that trial (from expt.listConds)
%                                   - word: the number of the word that was said (from expt.allWords)
%                                   - cond: the number of the condition that was used for that trial (from expt.allConds)
%                                   - bPerturb: whether or not there was a perturbation on that trial (taken from
%                                   expt.pertMag)
%                                   - bExcl: if the trial has been marked as bad
%                                   - bFlip: if the order of the user events is off (according to arpabet string) 
% 

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
if nargin < 4 || isempty(textField), textField = 'stimulusText'; end

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

if nargin < 5 || isempty(seg_list), seg_list = 'all'; end

%%
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

%% This is for finding the correct tokens if there is more than one stimulus in a study 
for i = 1:length(expt.words)
    word = expt.words{i}; 
    ix.(word) = find(expt.allWords == i); 
end

%% Get all unique arpabet strings for the stimuli in the study 
exptPhrases = []; 
for s = 1:length(expt.(textField))
    singlePhrase = []; 
    stimulusText = expt.(textField){s}; 
    splitStim = split(stimulusText, ' '); % Split by spaces into cells so you can string together the whole tihng
    
    % go through each word and get the arpabet for it 
    for p = 1:length(splitStim)
        stimPart = splitStim{p}; 
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

        % Strip out numbers that mark stress (this is what UEVs do from MFA) 
        for q = 1:length(arpaStimPart)
            arpa = arpaStimPart{q};
            arpa(regexp(arpa,'[0,1,2]'))=[];
            arpaStimPart{q} = char(arpa);
        end

        singlePhrase = [singlePhrase arpaStimPart]; 
    end

    exptPhrases{s} = singlePhrase;
end

% exptPhrases has all of the unique arpabet sequences for the stimuli used in the experiment. They are in the order of the
% stimuli, e.g. words or stimulusText. This will be used to index in 

%% Extract data from each trial

e = 1; % error trial counter
errorTrials = []; 
fprintf('Generating dataVals for %s... ', buffertype)
bSkip = 0; 
for i = 1:length(sortedTrialnums)
    trialnum = sortedTrialnums(i);
    filename = sortedFilenames{i};
    print_locationInLoop(trialnum, 25, i); 

    trialStimulus = exptPhrases{expt.(['list' upper(textField(1)) textField(2:end)])(trialnum)}; 
    
    % Load in the trial.mat file 
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
