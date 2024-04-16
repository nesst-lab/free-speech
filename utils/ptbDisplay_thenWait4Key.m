function [timedout] = ptbDisplay_thenWait4Key(continueKey, wait4break, win)

if nargin < 1 || isempty(continueKey), continueKey = KbName('space'); end
if nargin < 2 || isempty(wait4break), wait4break = 60; end % 60 seconds

% "Flip" the screen (show what you just created) 
Screen('Flip',win); 

% Then tell PTB to only wait for a specific key 
RestrictKeysForKbCheck(continueKey); 
ListenChar(1); 
tStart = GetSecs; 
timedout = 0;
while ~timedout 
    % Wait for spacebar (or whatever the continue key is) 
    [ keyIsDown, keyTime, ~] = KbCheck;
    if keyIsDown, break; end
    rt = keyTime - tStart; 
    % If you wait too long, say it's timed out
    if rt > wait4break, timedout = 1; end
end

% When pressed (or timed out), then make blank
Screen('FillRect', win, [0 0 0]);
Screen('Flip',win); 

clear keyIsDown keyTime rt
pause(0.5); % Give variables time to clear 
end