function check_emaLevels(what2check)
if nargin < 1
        what2check = questdlg({'Do you want to record'; ...
        '(a): A bite block recording';...
        '(b): A stationary head position sweep?'},'What do you want to check?','(a)','(b)','(a)');
end

%% set up screens

% Choose display (highest dislay number is a good guess)
Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');
screenNumber = max(screens);
cloneScreenNumber = max(screens) - 1; %RK 0 is fullscreen. This works when the second screen is to the right
[screenWidthpx, screenHeightpx] = Screen('WindowSize', screenNumber); 

% Establish main window
[win, rect] = Screen('OpenWindow', screenNumber);

% And controller (clone) window
[cloneWin, cloneRect] = Screen('OpenWindow', cloneScreenNumber, [0 0 0], [10 10 screenWidthpx/2, screenHeightpx/2]);

windowPointers = [win, cloneWin]; 
winHeights = [rect(3), cloneRect(3)]; 

% For continue key (pedal automatically maps to b) 
key2continue = 'b'; 
continueKey = KbName(key2continue); 
keyCode = zeros(1, 256); % Initiating variable so that it doesn't error out 

space2continue(1) = 'Press the pedal to continue.'; 
space2continue(2) = 'Press B to continue'; 

% Set font parameters
fontSizes = [40 30]; 
for w = 1:length(windowPointers)
    Screen('TextFont', windowPointers(w), 'Arial');
    Screen('TextSize', win, fontSizes(w));
end

% Black screen
for w = 1:length(windowPointers)
    Screen('FillRect', windowPointers(w), [255 255 255]);
    Screen('Flip',windowPointers(w)); 
end


%% run test
switch what2check
    case '(a)' % Bite block
        %% test mic and headphones
        % give instructions and wait for keypress

        biteInstruct1 = 'We are going to make a recording of the angle of your mouth.'; 
        biteInstruct2 = 'Take the bite block and gently bite down on it.'; 
        biteInstruct3 = 'When you are settled with the bite block, we will start the recording.'; 
        biteInstruct4 = 'You will see a countdown from 5. Hold still until you see the word RELAX.'; 
        
        biteInstructions = sprintf('%s\n%s\n%s\n%s\n', biteInstruct1, biteInstruct2, biteInstruct3, biteInstruct4); 
        
        for w = 1:length(windowPointers)
            DrawFormattedText(windowPointers(w),taskDetailsText,'center','center',[0 0 0], expt.instruct.txtparams.wrapat);
            DrawFormattedText(windowPointers(w),space2continue{w},'center',winHeights(w)*0.4,[0 0 0], expt.instruct.txtparams.wrapat);
            Screen('Flip',windowPointers(w)); 
        end
        
        
        %% test headphone level
        Audapter('reset'); 
        Audapter('start'); 
        h_ready = draw_exptText(h_fig,-.3,.5,sprintf(['Level testing has started.\n\n' ...
            'Be sure headphones are plugged into output 2 of headphone amplifier.\n\n' ...
            'Make sure SPL meter settings are:\n\t\tNo max or min\n\t\tA mode\n\t\tSlow\n\t\tLevel 50-100 db\n\n' ...
            'Place SPL meter in headphones without foam cover.\n' ...
            'Noise level should be ~60dB.\n' ...
            'If levels are off, adjust "pp headphones" knob on headphone amplifier.\n\n' ...
            'Press any key to stop once levels are confirmed.']),'Color','white','FontSize',35);
        pause
        Audapter('stop');
        delete_exptText(h_fig,h_ready)

    case '(b)'
        %% test headphone level
        Audapter('reset'); 
        Audapter('start'); 
        get_figinds_audapter;
        figure(h_fig(dup));
        h_ready_dup = text(-0.4, 0.5, sprintf(['Level testing has started.\n\n' ...
            'Be sure headphones are plugged into output 2 of headphone amplifier.\n\n' ...
            'Make sure SPL meter settings are:\n\t\tNo max or min\n\t\tA mode\n\t\tSlow\n\t\tLevel 50-100 db\n\n' ...
            'Place SPL meter in headphones without foam cover.\n' ...
            'Noise level should be ~80db while pp says "head".\n' ...
            'Adjust the microphone gain ("experiment mic") if this is too low or too high.\n\n' ...
            'Press any key to stop once levels are confirmed.']), 'Color','white','FontSize',35);
        figure(h_fig(stim));
        h_ready_stim = text(0, 0.5, sprintf('Please say "head" with the vowel stretched out \n                until the noise goes away.'), 'Color','white','FontSize',35);
        pause
        Audapter('stop');
        delete_exptText(h_fig,h_ready_dup)
        delete_exptText(h_fig,h_ready_stim)
end
       
        %% clean up
        close all
end