function [] = set_signalOutUserEvents(dataPath,trials)
% This is a generic function that should work for most studies with standard temporal perturbations. 
% 
% The goal of this function is to take information from hand-corrected trials in signalIn, and generate (or move) user events
% in signalOut correspondingly. This includes: 
%   - Starting at the position of the events in signalIn
%   - Using unperturbed trials (trials that have pertMag set to 0!) 
%   - Shifting all events by the hardware lag (relative to signalIn events)
%   - For perturbed trials, finding the onset and offset of perturbation, and shifting the events between those by pertMag
% 
% You will need: 
%   - hand-corrected trials, in the trials folder (1.mat, 2.mat, etc.) 
%   - expt.mat: needs to have: 
%       - expt.pertMag (list of perturbation magnitudes for each trial)
%   - data.mat 
%       - params (to get the 
%       - ost_stat (to get the original times when OSTs were achieved)
%       - pcfLine (to get the information about when the perturbation window was relative to the OST)
% All of these should be in the folder specified in the input argument dataPath
% 
% INPUTS
%       dataPath            the path to the folder that has all of the above information. Defaults to pwd
% 
%       trials              the trials that you want to set. Defaults to all (specifically, all trials available in the trial
%                           folder, not all trials in expt). 
% 
% Copies over times and names, finds the computational and/or perturbation lag by cross-correlating signalIn and signalOut, 
% and adjusts times accordingly. 
% 
% Altered from same function for cerebTimeAdapt and taimComp
%
% Initiated RK 2024-08-07; edited SB 2024-12-13; revised RK 2025-01-02; updated SB 2025-02-11 
% Copied by MR 2025-06-26 for use in new study deftAcoustic

dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = pwd; end
% default for trials set when expt is loaded

%%

% set directories for in/out 
trialInDir = 'trials';
trialOutDir = 'trials_signalOut'; 

% load expt and data files
fprintf('Loading data... ')
load(fullfile(dataPath,'expt.mat'));
load(fullfile(dataPath,'data.mat'));
fprintf('Done.\n')

% Check for wave viewer params 
if exist(fullfile(dataPath,'wave_viewer_params.mat'),'file')
    load(fullfile(dataPath,'wave_viewer_params.mat'));
else
    sigproc_params = get_sigproc_defaults;
end
if nargin < 2 || isempty(trials), trials = 1:expt.ntrials; end

% Set folders that will be used for trial files
trialInPath = fullfile(dataPath,trialInDir); % e.g. trials; trials_default
trialOutPath = fullfile(dataPath,trialOutDir);
if ~exist(trialOutPath,'dir')
    mkdir(trialOutPath)
end

% Get information about what trials actually exist 
[allTrialnums,allFilenames] = get_sortedTrials(trialInPath); 
sortedFilenames = allFilenames(ismember(allTrialnums,trials)); 
sortedTrialnums = allTrialnums(ismember(allTrialnums,trials)); 

% Get trial subsets
perturbAmount = expt.pertMag;

% Trials that were perturbed vs. unperturbed 
pertTrials = find(expt.pertMag ~= 0); 
nopertTrials = find(expt.pergMag == 0);  % These are used to calculate hardware lag

% Trials where there was speech feedback vs. no speech feedback
audParams = [data.params]; 
fbStyle = [audParams.fb]; 
noiseModes = [0 2 4]; % no feedback. noise only. modulated noise. 
noiseTrials = find(ismember(fbStyle, noiseModes)); 
speechTrials = find(~ismember(fbStyle, noiseModes)); 



%% Calculate offsetMs based on baseline trials regardless of what trials you're trying to set
hardwareLagTrials = intersect(speechTrials, nopertTrials); % Should be something like baseline and washout. 
unperturbedLag = []; % initiate variable
fprintf('Calculating experiment-wide hardware lag...\n'); 
for trialnum = hardwareLagTrials
    filename = [num2str(trialnum) '.mat']; 
    idx = find(allTrialnums == trialnum); 
    if isempty(idx)
        fprintf('Trial number %d not found in data folder. Skipping.\n', trialnum); 
        continue; 
    end
    load(fullfile(trialInPath,filename)); 

    [r,lags] = xcorr(data(trialnum).signalOut,data(trialnum).signalIn);
    [rmax,imax] = max(r);
    offsetMs = lags(imax)/data(trialnum).params.sr; % This is constant for baseline/washout
    unperturbedLag(end +1) = offsetMs; % compiling to apply the average to noise trials later
end

meanOffsetMs = mean(unperturbedLag, 'omitnan'); 
%%
e = 1; 
prints = 1; 
if ~isempty(speechTrials)
    fprintf('\nArranging signalOut user events for trial '); 
end
for i = 1:length(speechTrials)
    trialnum = speechTrials(i);
    print_locationInLoop(trialnum, 25, prints); 
    prints = prints+1; 
    filename = [num2str(trialnum) '.mat']; 
    idx = find(sortedTrialnums == trialnum);
    if isempty(idx)
       fprintf('Trial number %d not found in data folder. Skipping.\n', trialnum); 
       continue; 
    end
    savefileOut = fullfile(dataPath,trialOutDir,filename);
    load(fullfile(trialInPath,filename));  

    times = struct(); % Initiate 
    
    % get user-created events
    if exist('trialparams','var') ...
            && isfield(trialparams,'event_params') ...
            && ~isempty(trialparams.event_params)
        user_event_times = trialparams.event_params.user_event_times;
        user_event_names = trialparams.event_params.user_event_names; 

        [chron_user_event_times, chronix] = sort(user_event_times); 
        chron_user_event_names = user_event_names(chronix); % In case someone added an event in later and so it's out of order
    else
        user_event_times = [];
        user_event_names = {}; 
        warning('No events for trial %d\n',trialnum); 
    end
    % n_events = sum(~cellfun(@isempty, user_event_names));
    % if n_events > max_events
    %     warning('%d events found in trial %d (expected up to %d)',n_events,trialnum,max_events);
    %     fprintf('ignoring event %d\n',max_events+1:n_events)
    % elseif n_events < min_events
    %     warning('Only %d events found in trial %d (expected at least %d)',n_events,trialnum,min_events);
    %     fprintf('Check for empty values.\n')
    %     errorTrialsIn(e) = trialnum; 
    %     e = e+1; 
    % end

    % event times 
    for e = 1:length(chron_user_event_names)
        if e == 1
            chron_user_event_names{e} = 'trialStart'; % This is just to aid with finding the correct times, etc.---will be put back to empty later
        elseif e == length(chron_user_event_names)
            chron_user_event_names{e} = 'phraseEnd';
        end
        user_event_name = chron_user_event_names{e};  
        times.(user_event_name) = user_event_times(strcmp(user_event_names,user_event_name)); % This is fine; you just have to use chrons together or not-chrons together
    end
         
    if isfield(trialparams.event_params, 'is_good_trial')
        if trialparams.event_params.is_good_trial == 0
            bGoodTrial = 0; 
        else
            bGoodTrial = 1; 
        end
    else 
        bGoodTrial = 1; 
    end

    % load in out trials 
    if exist(fullfile(trialOutPath,filename),'file')
        load(fullfile(trialOutPath,filename));
    else
        sigmat = []; % set to blank; trialparams will just load in from signalIn but sigmat has to be recalculated when opening audioGUI for the first time on that trial
    end
    
    % Every trial needs to be shifted over by the hardware lag
    output_user_event_times = chron_user_event_times; % initiate---use the chronologically sorted ones so that you can set first event properly
    output_user_event_times(2:end) = output_user_event_times(2:end) + meanOffsetMs; % You only need to set the actual events; trial beg should be the same
    output_user_event_names = chron_user_event_names; % Use chrons together 

    % Only perturbed trials need to be shifted over by the perturbation in addition (and only some events)
    if ismember(trialnum, pertTrials)
        % Calculate when warping began by OST shifts 
        ostList = data(trialnum).ost_stat; 
        pcfLine = data(trialnum).pcfLine; 
        ostTrigger = pcfLine(1); % this is the trigger status
        triggerSample = find(ostList == ostTrigger, 1, 'first'); 
        triggerTime = triggerSample/(data(trialnum).params.sRate / data(trialnum).params.frameLen); 
        prewarpTime = triggerTime + pcfLine(2); % this is the time to wait after finding the status 
        endwarpTime = prewarpTime + pcfLine(3) + pcfLine(4); % how long the sample is + durHold 

        for e = 2:length(output_user_event_names)-1
            targetEvent = output_user_event_names{e}; 
            targetEventIx = find(strcmp(output_user_event_names,targetEvent)); 

            if times.(targetEvent) > prewarpTime && times.(targetEvent) < endwarpTime
                % If you're in the middle of warping (after trigger, before durHold is up), 
                % then add perturbamount
                output_user_event_times(targetEventIx) = output_user_event_times(targetEventIx) + perturbAmount(trialnum); 
            end
        end      
        
    end
     
    trialparams.event_params.is_good_trial = bGoodTrial; 
    
    % Change the output user names back to empty 
    output_user_event_names{1} = ''; 
    output_user_event_names{end} = ''; 
    
    % and save. These will be chronological, which might not match signalIn. But that should be okay, I think. 
    trialparams.event_params.user_event_names = output_user_event_names; 
    trialparams.event_params.user_event_times = output_user_event_times;
    save(savefileOut,'sigmat','trialparams')
     
end

%% If you have any noised trials, then you'll just shift everything over by the hardware lag. 
% I'm not sure why this is done separately from the not noised trials? 
if ~isempty(noiseTrials)
    fprintf('\nArranging signalOut user events for noised trial ');
end
prints = 1; 
for j = 1:length(noiseTrials)
    trialnum = noiseTrials(j);
    print_locationInLoop(trialnum, 25, prints); 
    prints = prints+1; 
    filename = [num2str(trialnum) '.mat']; 
    idx = find(sortedTrialnums == trialnum);
    if isempty(idx)
       fprintf('Trial number %d not found in data folder. Skipping.\n', trialnum);
       continue; 
    end
    savefileOut = fullfile(dataPath,trialOutDir,filename);
    load(fullfile(trialInPath,filename));

     % get user-created events
    if exist('trialparams','var') ...
            && isfield(trialparams,'event_params') ...
            && ~isempty(trialparams.event_params)
        user_event_times = trialparams.event_params.user_event_times;
        user_event_names = trialparams.event_params.user_event_names; 

        [chron_user_event_times, chronix] = sort(user_event_times); 
        chron_user_event_names = user_event_names(chronix); % In case someone added an event in later and so it's out of order
    else
        user_event_times = [];
        user_event_names = {}; 
        warning('No events for trial %d\n',trialnum); 
    end
    % n_events = sum(~cellfun(@isempty, user_event_names));
    % if n_events > max_events
    %     warning('%d events found in trial %d (expected up to %d)',n_events,trialnum,max_events);
    %     fprintf('ignoring event %d\n',max_events+1:n_events)
    % elseif n_events < min_events
    %     warning('Only %d events found in trial %d (expected at least %d)',n_events,trialnum,min_events);
    %     fprintf('Check for empty values.\n')
    %     errorTrialsIn(e) = trialnum; 
    %     e = e+1; 
    % end

    % Name the blank ones 
    for e = 1:length(chron_user_event_names)
        if e == 1
            chron_user_event_names{e} = 'trialStart'; % This is just to aid with finding the correct times, etc.---will be put back to empty later
        elseif e == length(chron_user_event_names)
            chron_user_event_names{e} = 'phraseEnd';
        end
        user_event_name = chron_user_event_names{e};  
        times.(user_event_name) = user_event_times(strcmp(user_event_names,user_event_name)); % This is fine; you just have to use chrons together or not-chrons together
    end
         
    if isfield(trialparams.event_params, 'is_good_trial')
        if trialparams.event_params.is_good_trial == 0
            bGoodTrial = 0; 
        else
            bGoodTrial = 1; 
        end
    else 
        bGoodTrial = 1; 
    end

    % load in out trials 
    if exist(fullfile(trialOutPath,filename),'file')
        load(fullfile(trialOutPath,filename));
    else
        sigmat = []; % set to blank; trialparams will just load in from signalIn but sigmat has to be recalculated when opening audioGUI for the first time on that trial
    end
    
    % Every trial needs to be shifted over by the hardware lag
    output_user_event_times = chron_user_event_times; % initiate---use the chronologically sorted ones so that you can set first event properly
    output_user_event_times(2:end) = output_user_event_times(2:end) + meanOffsetMs; % You only need to set the actual events; trial beg should be the same
    output_user_event_names = chron_user_event_names; % Use chrons together 

    trialparams.event_params.is_good_trial = bGoodTrial; 
    
    % Change the output user names back to empty 
    output_user_event_names{1} = ''; 
    output_user_event_names{end} = ''; 
    
    % and save. These will be chronological, which might not match signalIn. But that should be okay, I think. 
    trialparams.event_params.user_event_names = output_user_event_names; 
    trialparams.event_params.user_event_times = output_user_event_times;
    save(savefileOut,'sigmat','trialparams')

end

fprintf('\nDone.\n')

end