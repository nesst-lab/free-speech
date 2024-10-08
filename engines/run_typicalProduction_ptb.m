function [expt] = run_typicalProduction_ptb(expt,trials2run)
% Trial engine for typical production tasks. This is a version that is in free-speech and to be used with any type of typical
% production study; cerebellar-battery has a function that is named the same. 
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
cloneScreenNumber = max(screens) - 1; %RK 0 is fullscreen. This works when the second screen is to the right
[screenWidthpx, screenHeightpx] = Screen('WindowSize', screenNumber); 
windowPointers = Screen('Windows'); 
if ~isfield(expt, 'win') || isempty(windowPointers) % If you haven't saved an expt.win pointer or there are no current open PTB windows 
    [win, rect] = Screen('OpenWindow', screenNumber);
    expt.win = win; 
else
    if ~ismember(expt.win, windowPointers)
        [win, rect] = Screen('OpenWindow', screenNumber); 
    else
        win = expt.win;
    end
end


if ~isfield(expt, 'cloneWin') || length(windowPointers) == 1 % If you haven't saved an expt.win pointer or there are no current open PTB windows 
    [cloneWin, cloneRect] = Screen('OpenWindow', cloneScreenNumber, [0 0 0], [10 10 screenWidthpx/2, screenHeightpx/2]);
    expt.cloneWin = cloneWin; 
else
    if ~ismember(expt.cloneWin, windowPointers)
        [cloneWin, cloneRect] = Screen('OpenWindow', cloneScreenNumber, [0 0 0], [10 10 screenWidthpx/2, screenHeightpx/2]); 
    else
        cloneWin = expt.cloneWin;
    end
end

windowPointers = [win, cloneWin]; 
winHeights = [rect(3), cloneRect(3)]; 
% For spacebar to continue
key2continue = 'space'; 
continueKey = KbName(key2continue); 
if ~isfield(expt.instruct, 'space2continue') 
    expt.instruct.space2continue = ['Press ' upper(key2continue) ' to continue']; 
end
key2pause = 'p'; 
pauseKey = KbName(key2pause); 
keyCode = zeros(1, 256); % Initiating variable so that it doesn't error out 

% Set font parameters
for w = 1:length(windowPointers)
    Screen('TextFont', windowPointers(w), 'Arial');
    Screen('TextSize', win, expt.instruct.txtparams.FontSize(w));
end

 % Don't do this to clone because it is small 

%% Set up audio devices 

% Get location of Scarlett
InitializePsychSound;   % set up Psychtoolbox audio mex
wasapiDevices = PsychPortAudio('GetDevices',13); % 13 is WASAPI
deviceNames = {wasapiDevices.DeviceName}; 
scarletts = find(contains(deviceNames, 'Focusrite') & ~contains(deviceNames, 'Loopback')); % 
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
for w = 1:length(windowPointers)
    Screen('FillRect', windowPointers(w), [0 0 0]);
    Screen('Flip',windowPointers(w)); 
end

% Instructions like "in this task, you will see words on the screen" 
if isfield(expt.instruct, 'taskDetails')
    taskDetailsText = expt.instruct.taskDetails;  
    for w = 1:length(windowPointers)
        DrawFormattedText(windowPointers(w),taskDetailsText,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
        DrawFormattedText(windowPointers(w),expt.instruct.space2continue,'center',winHeights(w)*0.4,[255 255 255], expt.instruct.txtparams.wrapat);
        Screen('Flip',windowPointers(w)); 
    end
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

    for w = 1:length(windowPointers)
        Screen('FillRect', windowPointers(w), [0 0 0]);
        Screen('Flip',windowPointers(w)); 
    end

    clear keyIsDown 
    clear keyTime  
    clear rt
    pause(0.5); % Give variables time to clear 
end

% Instructions like "you will see words X, Y, and Z" 
if isfield(expt.instruct, 'whichWords')
    whichWordsText = expt.instruct.whichWords;  

    % Participant sees words
    DrawFormattedText(win,whichWordsText,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
    Screen('Flip',win); 
    
    % Experimenter sees instructions on what to say
    experimenterText = 'Read the main instructions to the participant.'; 
    DrawFormattedText(cloneWin,experimenterText,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
    DrawFormattedText(cloneWin,expt.instruct.space2continue,'center',winHeights(2)*0.4,[255 255 255], expt.instruct.txtparams.wrapat);
    Screen('Flip',cloneWin); 
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

    for w = 1:length(windowPointers)
        Screen('FillRect', windowPointers(w), [0 0 0]);
        Screen('Flip',windowPointers(w)); 
    end
end

for w = 1:length(windowPointers)
    Screen('FillRect', windowPointers(w), [0 0 0]);
    Screen('Flip',windowPointers(w)); 
end

clear keyIsDown 
clear keyTime  
clear rt
pause(0.5); % Give variables time to clear 

% Introduction to which round you're doing (practice, full) 
if isfield(expt.instruct, 'roundDetails')
    whichWordsText = expt.instruct.roundDetails;  
    for w = 1:length(windowPointers)
        DrawFormattedText(windowPointers(w),whichWordsText,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
        DrawFormattedText(windowPointers(w),expt.instruct.space2continue,'center',winHeights(w)*0.4,[255 255 255], expt.instruct.txtparams.wrapat);
        Screen('Flip',windowPointers(w)); 
    end
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

    for w = 1:length(windowPointers)
        Screen('FillRect', windowPointers(w), [0 0 0]);
        Screen('Flip',windowPointers(w)); 
    end
end

for w = 1:length(windowPointers)
    Screen('FillRect', windowPointers(w), [0 0 0]);
    Screen('Flip',windowPointers(w)); 
end

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
    Screen('TextSize', win, expt.instruct.txtparams.FontSize(1)*2);

    while ~bGoodTrial
        % pause if 'p' is pressed ? 

        % set trial index
        trial_index = trials2run(itrial);
                     
        % Black screen 
        for w = 1:length(windowPointers)
            Screen('FillRect', windowPointers(w), [0 0 0]);
            Screen('Flip',windowPointers(w)); 
        end
        
        % Start recording
        trialDur = expt.timing.stimdur; 
        PsychPortAudio('GetAudioData', h_speechInput, trialDur+1); % Preallocate output buffer with 0s 
        PsychPortAudio('Start', h_speechInput, 0, 0, 1);  

        % set text
        txt2display = expt.listStimulusText{trial_index};         
        
        % display stimulus
        for w = 1:length(windowPointers)
            DrawFormattedText(windowPointers(w),txt2display,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
            Screen('Flip',windowPointers(w)); 
        end
        
        % Pause for trial duration. Listen for a p in the meantime
        RestrictKeysForKbCheck(pauseKey);
        ListenChar(1)
        tStart = GetSecs; 
        timedout = 0; 
        while ~timedout
            % Wait for spacebar
            [ keyIsDown, keyTime, keyCode] = KbCheck;
            if keyIsDown, break; end 
            rt = keyTime - tStart; 
            if rt > expt.timing.stimdur, timedout = 1; end
        end
        % WaitSecs(expt.timing.stimdur);
        
        % Stop capturing audio
        PsychPortAudio('Stop', h_speechInput);

        % If they pressed p, show a pause 
        if find(keyCode == 1) == pauseKey      
            keyCode = pause_trials_ptb(expt, windowPointers, winHeights);  
            clear keyIsDown 
            clear keyTime  
            clear rt
            ListenChar(0); 
        end
        
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
        for w = 1:length(windowPointers)
            Screen('FillRect', windowPointers(w), [0 0 0]);
            Screen('Flip',windowPointers(w)); 
        end
          
        % Display a "please speak louder" a la PTB if not loud enough
        if ~bGoodTrial
            thresholdRepeat = thresholdRepeat + 1; 
            for w = 1:length(windowPointers)
                DrawFormattedText(windowPointers(w),'Please try to speak a little louder','center','center',[255 255 0], expt.instruct.txtparams.wrapat);
                Screen('Flip',windowPointers(w)); 
            end
            WaitSecs(1); 
            for w = 1:length(windowPointers)
                Screen('FillRect', windowPointers(w), [0 0 0]);
                Screen('Flip',windowPointers(w)); 
            end
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

        % add intertrial interval + jitter and also wait for a pause 
        RestrictKeysForKbCheck(pauseKey);
        ListenChar(1)
        tStart = GetSecs; 
        timedout = 0; 
        while ~timedout
            % Wait for spacebar
            [ keyIsDown, keyTime, keyCode] = KbCheck;
            if keyIsDown, break; end 
            rt = keyTime - tStart; 
            if rt > expt.timing.interstimdur + rand*expt.timing.interstimjitter, timedout = 1; end
        end

        % If they pressed p, show a pause 
        if find(keyCode == 1) == pauseKey      
            keyCode = pause_trials_ptb(expt, windowPointers, winHeights);  
            clear keyIsDown 
            clear keyTime  
            clear rt
            ListenChar(0); 
        end


    end
    % display break text
    if itrial == length(trials2run) && ismember(expt.listConds{itrial},{'practice','full'})
        breaktext = sprintf('Thank you!\n\nPlease wait.');
        for w = 1:length(windowPointers)
            DrawFormattedText(windowPointers(w),breaktext,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
            Screen('Flip',windowPointers(w)); 
        end
        WaitSecs(3); 
        for w = 1:length(windowPointers)
            Screen('FillRect', windowPointers(w), [0 0 0]);
            Screen('Flip',windowPointers(w)); 
        end
    elseif any(expt.breakTrials == trial_index)
        breaktext = sprintf('Time for a break!\n%d of %d trials done.\n\nPress the space bar to continue.',trials2run(itrial),expt.ntrials);
        for w = 1:length(windowPointers)
            DrawFormattedText(windowPointers(w),breaktext,'center','center',[255 255 255], expt.instruct.txtparams.wrapat);
            Screen('Flip',windowPointers(w)); 
        end
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
        for w = 1:length(windowPointers)
            Screen('FillRect', windowPointers(w), [0 0 0]);
            Screen('Flip',windowPointers(w)); 
        end
        clear keyIsDown 
        clear keyTime  
        clear rt
        pause(expt.timing.pausebuffer); % Give variables time to clear 
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


