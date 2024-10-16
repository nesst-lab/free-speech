function check_emaLevels(what2check)
if nargin < 1
        what2check = questdlg({'Do you want to record'; ...
        '(a): A bite block recording';...
        '(b): A stationary head position sweep?'},'What do you want to check?','(a)','(b)','(a)');
end

%%
bManualEma = askNChoiceQuestion('Are you manually triggering the EMA?', {'yes', 'no'}); 
if strcmp(bManualEma, 'yes')
    setSweepInstructions = sprintf('\n\n ** Please set the sweep length to 5 seconds, then type OK. ** \n\n'); 
    askNChoiceQuestion(setSweepInstructions, {'ok' 'OK' 'Ok'}, 0); 
end

%% set up screens

% Choose display (highest dislay number is a good guess)
Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');
screenNumber = max(screens);
cloneScreenNumber = max(screens) - 1; %RK 0 is fullscreen. This works when the second screen is to the right
[screenWidthpx, screenHeightpx] = Screen('WindowSize', screenNumber); 

% Establish main window
[win, rect] = Screen('OpenWindow', screenNumber, [0 0 0]);

% And controller (clone) window
[cloneWin, cloneRect] = Screen('OpenWindow', cloneScreenNumber, [0 0 0], [10 10 screenWidthpx/2, screenHeightpx/2]);

windowPointers = [win, cloneWin]; 
winHeights = [rect(3), cloneRect(3)]; 

% For continue key (pedal automatically maps to b) 
key2continue = 'b'; 
continueKey = KbName(key2continue); 
yesKeys = [97 49]; 
noKeys = [96 48]; 
keyCode = zeros(1, 256); % Initiating variable so that it doesn't error out 

space2continue{1} = 'Press the pedal to continue.'; 
space2continue{2} = 'Press B to continue'; 

% Set font parameters
fontSizes = [40 25]; 
for w = 1:length(windowPointers)
    Screen('TextFont', windowPointers(w), 'Arial');
    Screen('TextSize', windowPointers(w), fontSizes(w));
end

% Black screen
for w = 1:length(windowPointers)
    Screen('FillRect', windowPointers(w), [0 0 0]);
    Screen('Flip',windowPointers(w)); 
end

wrapat = 60; 
bDoneRecording = 0; 

%% run test
switch what2check
    case '(a)' % Bite block
        %% bite plane
        folderName = 'biteplane'; 
        % give instructions and wait for keypress

        biteInstruct1 = 'We are going to make a recording of the angle of your mouth.'; 
        biteInstruct2 = 'Take the bite block and gently bite down on it.'; 
        biteInstruct3 = 'When you are settled with the bite block, we will start the recording.'; 
        biteInstruct4 = 'You will see a countdown from 5. Hold still until the end of the countdown.'; 
        
        biteInstructions = sprintf('%s\n\n%s\n\n%s\n\n%s\n', biteInstruct1, biteInstruct2, biteInstruct3, biteInstruct4); 

        % Trigger sweep
        prepareInstructions = 'Please bite down lightly on the bite block now, and hold still.'; 
        sweepInstructions = 'Trigger the sweep now.'; 

        % Get ready to hold
        holdInstructions1 = 'Please bite down lightly on the bite block now, and hold still.'; 
        holdInstructions = sprintf('%s\n\n', holdInstructions1); 

        % Relax
        relaxInstructions1 = 'You can relax now.'; 
        relaxInstructions = sprintf('%s\n\n', relaxInstructions1); 

        checkBiteplane1 = 'Check the biteplane measurement now.'; 
        checkBiteplane2 = 'Press 0 if you need to redo the biteplane. Press 1 if you are done.'; 
        checkBiteplaneInstructions = sprintf('%s\n\n%s\n\n', checkBiteplane1, checkBiteplane2); 
        

    case '(b)' % Plain holding still 
        folderName = 'headposition';

        biteInstruct1 = 'We are going to make a recording of the placement of the sensors.'; 
        biteInstruct2 = 'You will just be holding still for this recording.'; 
        biteInstruct3 = 'When you are ready, we will start the recording.'; 
        biteInstruct4 = 'You will see a countdown from 5. Hold still until the end of the countdown.'; 
        
        biteInstructions = sprintf('%s\n\n%s\n\n%s\n\n%s\n', biteInstruct1, biteInstruct2, biteInstruct3, biteInstruct4); 

        % Get ready to hold
        holdInstructions1 = 'Please hold still.'; 
        holdInstructions = sprintf('%s\n\n', holdInstructions1); 

        % Trigger sweep
        prepareInstructions = 'Please hold still.'; 
        sweepInstructions = 'Trigger the sweep now.'; 

        % Relax
        relaxInstructions1 = 'You can relax now.'; 
        relaxInstructions = sprintf('%s\n\n', relaxInstructions1); 

        checkBiteplane1 = 'Check the head position measurement now.'; 
        checkBiteplane2 = 'Press 0 if you need to redo the head position sweep. Press 1 if you are done.'; 
        checkBiteplaneInstructions = sprintf('%s\n\n%s\n\n', checkBiteplane1, checkBiteplane2); 
        
end

%% The actual running 
while ~bDoneRecording
    for w = 1:length(windowPointers)
        DrawFormattedText(windowPointers(w),biteInstructions,'center','center',[255 255 255], wrapat);
        DrawFormattedText(windowPointers(w),space2continue{w},'center',winHeights(w)*0.5,[255 255 255], wrapat);
        Screen('Flip',windowPointers(w)); 
    end
    
    % Wait for continue
    RestrictKeysForKbCheck(continueKey);
    ListenChar(1)
    tStart = GetSecs; 
    timedout = 0; 
    while ~timedout
        % Wait for spacebar
        [ keyIsDown, keyTime, ~] = KbCheck;
        if keyIsDown, break; end 
        rt = keyTime - tStart; 
        if rt > 600, timedout = 1; end
    end
    
    % Flip to black
    for w = 1:length(windowPointers)
        Screen('FillRect', windowPointers(w), [0 0 0]);
        Screen('Flip',windowPointers(w)); 
    end
    WaitSecs(1.5);  

    % Get ready
    DrawFormattedText(win,prepareInstructions,'center','center',[255 255 255], wrapat);
    if strcmp(bManualEma, 'yes')
        DrawFormattedText(cloneWin,sweepInstructions,'center','center',[255 20 20], wrapat);
    %else
        % programmatic trigger 
    end
    for w = 1:length(windowPointers)
        Screen('Flip',windowPointers(w)); 
    end
    WaitSecs(1.5); 
    
    % Tell them to hold still
    for w = 1:length(windowPointers)
        Screen('FillRect', windowPointers(w), [0 0 0]);
        Screen('Flip',windowPointers(w)); 
    end
        
    % Countdown 
    maxSecs = 5; 
    for i = maxSecs:-1:1
        DrawFormattedText(win,holdInstructions,'center','center',[255 255 255], wrapat);
        if strcmp(bManualEma, 'yes')
            DrawFormattedText(cloneWin,sweepInstructions, 'center','center', [100 50 50], wrapat); 
        end
        for w = 1:length(windowPointers)            
            DrawFormattedText(windowPointers(w),num2str(i),'center',winHeights(w)*0.45,[255 255 255], wrapat);
            Screen('Flip',windowPointers(w)); 
        end
        WaitSecs(1); 
    end
    
    % Flip to black 
    for w = 1:length(windowPointers)
        Screen('FillRect', windowPointers(w), [0 0 0]);
        Screen('Flip',windowPointers(w)); 
    end
    
    % Tell pp to relax, ask expt if it is okay 
    DrawFormattedText(win,relaxInstructions,'center','center',[255 255 255], wrapat);
    DrawFormattedText(cloneWin,checkBiteplaneInstructions,'center', 'center', [255 255 255], wrapat); 
    for w = 1:length(windowPointers)
        Screen('Flip',windowPointers(w)); 
    end
      
    RestrictKeysForKbCheck([yesKeys noKeys]);
    ListenChar(1)
    tStart = GetSecs; 
    timedout = 0; 
    while ~timedout
        % Wait for 1/0 input
        [ keyIsDown, keyTime, keyCode] = KbCheck;
        if keyIsDown, break; end 
        rt = keyTime - tStart; 
        if rt > 600, timedout = 1; end
    end
    whichKey = find(keyCode == 1); 
    switch whichKey
        case {96 48}
            bDoneRecording = 0; 
        case {97 49}
            bDoneRecording = 1; 
    end
    clear keyIsDown keyTime rt whichKey
    keyCode = zeros(1, 256); % Initiating variable so that it doesn't error out 
    pause(0.5); % Give variables time to clear 
    
    if ~bDoneRecording    
        adjustInstructions = sprintf('\nAdjust settings or participant as needed, then press B to do collection again.\n'); 
        Screen('FillRect', cloneWin, [0 0 0]);
        Screen('Flip', cloneWin); 
        DrawFormattedText(cloneWin,adjustInstructions,'center', 'center', [255 255 255], wrapat); 
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
            if rt > 600, timedout = 1; end
        end
        clear keyIsDown keyTime rt
        pause(0.5); % Give variables time to clear 
        fprintf('Retrying biteplane measure.\n')
    else
        thankInstructions = sprintf('\nThank you!\n\nPlease wait.\n'); 
        for w = 1:length(windowPointers)
            Screen('FillRect', windowPointers(w), [0 0 0]);
            Screen('Flip', windowPointers(w)); 
            DrawFormattedText(windowPointers(w),thankInstructions,'center', 'center', [255 255 255], wrapat); 
            Screen('Flip',windowPointers(w));
        end
        WaitSecs(2); 
    end       
end
       
Screen('CloseAll'); 

if strcmp(bManualEma, 'yes')
    renameRequest = sprintf('\n\n** Rename the "current" folder "%s", then type RENAMED and hit enter. ** \n\n', folderName); 
    askNChoiceQuestion(renameRequest, {'renamed', 'RENAMED', 'Renamed'}, 0);
end

end % EOF