function [expt] = run_typicalProduction_ptb(expt,trials2run)
% Trial engine for typical production tasks. Currently only used for cerebellar battery but could be used for anything,
% really. This is the PTB version, which will be used at UC-Berkeley. 
% 
% Areas that may have to be edited to run on different hardware/drive setups at different sites have been marked with TKTKTKTKT
% for easy search ability 
% 
% Notable required fields in expt: 
% 
%       listStimulusText                This engine relies on stimulusText rather than word to be flexible for languages that
%                                       may have a non-latinate writing system (e.g., Mandarin) 
% 
%       conds                           Use this for specifying practice vs. full experiment runs. Practice is specified as
%                                       'practice'; nothing relies on a specific name for the full experiment run 
% 
%       params                          With fields: fs (sampling rate)
%                                       rmsThresh (for checking goodness of trial). Example value: 0.04 
%                                       frameSize (for calculating RMS). Example value: 96 
% 
%       timing                          With fields: stimdur (duration of trial)
%                                       wait4break: how long to wait before forcing continuation/timeout
%                                       interstimdur: how long between trials
%                                       interstimjitter: range of jitter for interstimdur
% 
%       instruct.taskDetails            Displays instructions for the task. This can differ between practice and full runs
%                                       (for example), but will always display before the trials start. 
% 
%       instruct.txtparams.wrapat       N characters after which you would wrap instruction text
%                                       
%  
% Optional fields---these will display as long as the field exists, but will not if it is not a field
%       instruct.whichWords             Text to display the words that will be used. 
% 
%       instruct.roundDetails           Text to display if you are going to say "this is a practice round" or "this is a full
%                                       round" or whatever
% 
%       instruct.space2continue         Text to display for the "press space to continue" instruction. This is a separately
%                                       displayed line, not integrated into the other instructions. There is a default option
%                                       for this so you do not necessarily need to specify it. 
% 
% 
% 
% RPK initiated July 29 2022
% RPK transition to PTB from Audapter Sept 15 2022

dbstop if error

if nargin < 1, expt = []; end
if nargin < 2 || isempty(trials2run), trials2run = 1:expt.ntrials; end % not sure if this line really has to be here

%% Data drive setup and such 

if isfield(expt,'dataPath')
    % If you're doing the pretest phase, put in subfolder 
    outputdir = expt.dataPath; 
else
    warning('Setting output directory to current directory: %s\n',pwd);
    outputdir = pwd;
end

% assign folder for saving trial data
% create output directory if it doesn't exist
trialdirname = 'temp_trials';
trialdir = fullfile(outputdir,trialdirname);
if ~exist(trialdir,'dir')
    mkdir(outputdir,trialdirname)
end

repeatTrialdirname = 'repeat_trials'; 
repeatTrialdir = fullfile(outputdir,repeatTrialdirname); 
if ~exist(repeatTrialdir,'dir')
    mkdir(outputdir,repeatTrialdirname)
end

save([outputdir '\expt.mat'],'expt');
expt = set_exptDefaults(expt);



%% Set up screens

% Choose display (highest dislay number is a good guess)
Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');
screenNumber = max(screens); % TKTKTKTKT UCSF/BERKELEY potential edit site
[~, screenHeightpx] = Screen('WindowSize', screenNumber); 
windowPointers = Screen('Windows'); 
if ~isfield(expt, 'win') || isempty(windowPointers) % If you haven't saved an expt.win pointer or there are no current open PTB windows 
    win = Screen('OpenWindow', screenNumber);
    expt.win = win; 
else
    if ~ismember(expt.win, windowPointers)
        win = Screen('OpenWindow', screenNumber); 
    else
        win = expt.win;
    end
end

% For spacebar to continue
key2continue = 'space'; 
continueKey = KbName(key2continue); 
if ~isfield(expt.instruct, 'space2continue') 
    expt.instruct.space2continue = ['Press ' upper(key2continue) ' to continue']; 
end
key2pause = 'p'; 
pauseKey = KbName(key2pause); 

% Set font parameters
Screen('TextFont', win, 'Arial');
Screen('TextSize', win, expt.instruct.txtparams.FontSize);

%% Set up audio devices 

% Get location of Scarlett
InitializePsychSound;   % set up Psychtoolbox audio mex
wasapiDevices = PsychPortAudio('GetDevices',13); % 13 is WASAPI
deviceNames = {wasapiDevices.DeviceName}; 
scarletts = find(contains(deviceNames, 'Focusrite')); % TKTKTKTKT Berkeley/UCSF potential edit somewhere in here to make sure the right device is selected
inputDevs = find([wasapiDevices.NrInputChannels] > 0); 
inputScarlett = intersect(inputDevs, scarletts); 

% Some parameters for the audio playback device
latencyClass = 0; % This is "take full control of audio device, request most aggressive settings for device, fail if can't meet strictest reqs" 
% Note: we can't use 1 because we don't have ASIO drivers. 
% Other option is 0, which is "don't care about it being well-timed". Probably not ideal for this project. 
fs = expt.params.fs; 
nchannels = 1; 

% Set up recording device
h_speechInput = PsychPortAudio('Open', wasapiDevices(inputScarlett).DeviceIndex, 2, latencyClass, fs, nchannels);

%% Display instructions 
% General instructions. For practice this may be the task instructions ("you will read words as they appear on screen"). For
% main this may be something like "we will now continue with the main phase of the experiment." 

% Black screen
Screen('FillRect', win, [0 0 0]);
Screen('Flip',win); 

% Instructions like "in this task, you will see words on the screen" 
if isfield(expt.instruct, 'taskDetails')
    taskDetailsText = expt.instruct.taskDetails;  
    DrawFormattedText(win,taskDetailsText,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
    DrawFormattedText(win,expt.instruct.space2continue,'center',screenHeightpx*0.8,[255 255 255], expt.instruct.txtparams.wrapat);
    Screen('Flip',win); 
    RestrictKeysForKbCheck(continueKey);
    ListenChar(1)
    tStart = GetSecs; 
    timedout = 0; 
    while ~timedout
        % Wait for spacebar
        [ keyIsDown, keyTime, ~] = KbCheck;
        if keyIsDown, break; end 
        rt = keyTime - tStart; 
        if rt > expt.timing.wait4break, timedout = 1; end
    end

    Screen('FillRect', win, [0 0 0]);
    Screen('Flip',win); 

    clear keyIsDown 
    clear keyTime  
    clear rt
    pause(0.5); % Give variables time to clear 
end

% Instructions like "you will see words X, Y, and Z" 
if isfield(expt.instruct, 'whichWords')
    whichWordsText = expt.instruct.whichWords;  
    DrawFormattedText(win,whichWordsText,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
    DrawFormattedText(win,expt.instruct.space2continue,'center',screenHeightpx*0.8,[255 255 255], expt.instruct.txtparams.wrapat);
    Screen('Flip',win); 
    RestrictKeysForKbCheck(continueKey);
    ListenChar(1)
    tStart = GetSecs; 
    timedout = 0; 
    while ~timedout
        % Wait for spacebar
        [ keyIsDown, keyTime, ~] = KbCheck;
        if keyIsDown, break; end 
        rt = keyTime - tStart; 
        if rt > expt.timing.wait4break, timedout = 1; end
    end

    Screen('FillRect', win, [0 0 0]);
    Screen('Flip',win); 
end

Screen('FillRect', win, [0 0 0]);
Screen('Flip',win); 

clear keyIsDown 
clear keyTime  
clear rt
pause(0.5); % Give variables time to clear 

% Introduction to which round you're doing (practice, full) 
if isfield(expt.instruct, 'roundDetails')
    whichWordsText = expt.instruct.roundDetails;  
    DrawFormattedText(win,whichWordsText,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
    DrawFormattedText(win,expt.instruct.space2continue,'center',screenHeightpx*0.8,[255 255 255], expt.instruct.txtparams.wrapat);
    Screen('Flip',win); 
    RestrictKeysForKbCheck(continueKey);
    ListenChar(1)
    tStart = GetSecs; 
    timedout = 0; 
    while ~timedout
        % Wait for spacebar
        [ keyIsDown, keyTime, ~] = KbCheck;
        if keyIsDown, break; end 
        rt = keyTime - tStart; 
        if rt > expt.timing.wait4break, timedout = 1; end
    end

    Screen('FillRect', win, [0 0 0]);
    Screen('Flip',win); 
end

Screen('FillRect', win, [0 0 0]);
Screen('Flip',win); 

clear keyIsDown 
clear keyTime  
clear rt
pause(0.5); % Give variables time to clear 



%%
if expt.isRestart
    trials2run = trials2run(trials2run >= expt.startTrial);
end

%% Run the trials
for itrial = 1:length(trials2run)  % for each trial
    bGoodTrial = 0;
    thresholdRepeat = 0; 
    
    % Set a larger font size for the stimulus display 
    Screen('TextSize', win, expt.instruct.txtparams.FontSize*2);

    while ~bGoodTrial
        % pause if 'p' is pressed ? 

        % set trial index
        trial_index = trials2run(itrial);
                     
        % Black screen 
        Screen('FillRect', win, [0 0 0]);
        Screen('Flip',win); 
        
        % Start recording
        trialDur = expt.timing.stimdur; 
        PsychPortAudio('GetAudioData', h_speechInput, trialDur+1); % Preallocate output buffer with 0s 
        PsychPortAudio('Start', h_speechInput, 0, 0, 1);  

        % set text
        txt2display = expt.listStimulusText{trial_index};         
        
        % display stimulus
        DrawFormattedText(win,txt2display,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
        Screen('Flip',win); 
        
        % Pause for trial duration
        WaitSecs(expt.timing.stimdur);
        
        % Stop capturing audio
        PsychPortAudio('Stop', h_speechInput);
        
        % Fetch all audio data out of the buffer - Needs to be empty before next trial. 
        audioData = PsychPortAudio('GetAudioData', h_speechInput);
        
        % Stick audio data into audapter-like data structure 
        data.signalIn = audioData; 
        
        % Get RMS for loud enough speech purposes 
        overSamps = mod(length(audioData), expt.params.frameSize); 
        if overSamps
            padNans = nan(1, expt.params.frameSize - overSamps); 
            audioData = [audioData padNans]; 
        end
        % Make a matrix with one frame per row and one sample per column
        rmsdata = reshape(audioData, [], expt.params.frameSize); % 96 samples per RMS frame 'cause audapter standards.
        data.rms = rms(rmsdata, 2); % Calculates one RMS value per row 
        data.params = expt.params; 
%         data.ost_stat = zeros(1,length(data.rms)); % hack to make this run after mean commit

        % Check for loud enough speaking
        bGoodTrial = max(data.rms(:,1)) > expt.params.rmsThresh;
        if expt.bTestMode
           % if you're in test mode just set it to 1
            bGoodTrial = 1;             
        end
        
        % Clear screen 
        Screen('FillRect', win, [0 0 0]);
        Screen('Flip',win); 
          
        % Display a "please speak louder" a la PTB if not loud enough
        if ~bGoodTrial
            thresholdRepeat = thresholdRepeat + 1; 
            DrawFormattedText(win,'Please try to speak a little louder','center','center',[255 255 0], expt.instruct.txtparams.wrapat);
            Screen('Flip',win); 
            WaitSecs(1); 
            Screen('FillRect', win, [0 0 0]);
            Screen('Flip',win); 
        end        
        
        % save trial: use repeatTrialdirname if you've repeated, else use the normal one         
        if ~bGoodTrial && thresholdRepeat <= 2
            trialfile = fullfile(repeatTrialdir, sprintf('%d-%d.mat',trial_index,thresholdRepeat)); 
        else
            trialfile = fullfile(trialdir,sprintf('%d.mat',trial_index));
        end
        save(trialfile,'data')
        
        % If you've repeated twice already, then just continue onto next trial
        if thresholdRepeat > 2
            bGoodTrial = 1; 
        end

        % clean up data
        clear data

        % add intertrial interval + jitter
        pause(expt.timing.interstimdur + rand*expt.timing.interstimjitter);     

    end
    % display break text
    if itrial == length(trials2run) && ismember(expt.listConds{itrial},{'practice','full'})
        breaktext = sprintf('Thank you!\n\nPlease wait.');
        DrawFormattedText(win,breaktext,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
        Screen('Flip',win); 
        WaitSecs(3); 
        Screen('FillRect', win, [0 0 0]);
        Screen('Flip',win); 
    elseif any(expt.breakTrials == trial_index)
        breaktext = sprintf('Time for a break!\n%d of %d trials done.\n\nPress the space bar to continue.',trials2run(itrial),expt.ntrials);
        DrawFormattedText(win,breaktext,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
        Screen('Flip',win); 
        RestrictKeysForKbCheck(continueKey);
        ListenChar(1)
        tStart = GetSecs; 
        timedout = 0; 
        while ~timedout
            % Wait for spacebar
            [ keyIsDown, keyTime, ~] = KbCheck;
            if keyIsDown, break; end 
            rt = keyTime - tStart; 
            if rt > expt.timing.wait4break, timedout = 1; end
        end
        Screen('FillRect', win, [0 0 0]);
        Screen('Flip',win); 
        clear keyIsDown 
        clear keyTime  
        clear rt
        pause(0.5); % Give variables time to clear 
    end
    
end

%% write experiment data and metadata
if strcmp(expt.listConds{itrial},'practice') || trial_index == expt.ntrials
    
    % collect trials into one variable
    alldata = struct;
    fprintf('Processing data\n')
    for i = 1:trials2run(end)
        load(fullfile(trialdir,sprintf('%d.mat',i)))
        names = fieldnames(data);
        for j = 1:length(names)
            alldata(i).(names{j}) = data.(names{j});
        end
    end
    
    % save data
    fprintf('Saving data... ')
    clear data
    data = alldata;
    save(fullfile(outputdir,'data.mat'), 'data')
    fprintf('saved.\n')
    
    % collect repeated trials into one variable
    repeatdata = struct;
    repeatmats = dir(fullfile(repeatTrialdir,'*.mat')); 
    fprintf('Processing data\n')
    for i = 1:length(repeatmats)
        load(fullfile(repeatTrialdir,repeatmats(i).name))
        names = fieldnames(data);
        for j = 1:length(names)
            repeatdata(i).(names{j}) = data.(names{j});
        end
    end
    
    % save repeated data
    fprintf('Saving repeated trial data... ')
    clear data
    data = repeatdata;
    save(fullfile(outputdir,'repeat_data.mat'), 'repeatdata')
    fprintf('saved.\n')    
     
    % save expt
    fprintf('Saving expt... ')
    save(fullfile(outputdir,'expt.mat'), 'expt')
    fprintf('saved.\n')
    
    % remove temp trial directory
    fprintf('Removing temp directory... ')
    rmdir(trialdir,'s');
    fprintf('done.\n')
    
    % remove repeated temp trial directory
    fprintf('Removing repeated temp directory... ')
    rmdir(repeatTrialdir,'s');
    fprintf('done.\n')
    
end

%% close figures
Screen('CloseAll')


