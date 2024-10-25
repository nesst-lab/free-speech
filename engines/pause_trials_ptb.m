function [keyCode] = pause_trials_ptb(expt, windowPointers, winHeights, space2continuetxt, txtcolor, wincolor, key2continue)
% A function to put pauses into PTB experiment trial loops 
% 
% Needs the following: 
% 
%   expt                            normal expt structure. Specifically, it needs the fields: 
%       instruct.pausetxt           - What you want to say during the pause
%       instruct.space2continue     - The text you use to tell people to hit spacebar to continue (optional---can also
%                                   specify in space2continuetxt) 
%       instruct.txtparams.wrapat   - Formatting for when you want to wrap text
%       instruct.resumetxt          - What you want to say when they continue on
% 
%       timing.wait4break           - the maximum time you will wait for a pause to resume, in seconds (this should be quite large)
% 
%   windowPointers                  the PTB window or windows you want to draw on. Defaults to all PTB windows found with
%                                   Screen('Windows')
%
%   winHeights                      the heights of the PTB windows you want to draw on. Defaults to the number extracted from
%                                   Screen('WindowSize', windowPointers)
%
%   space2continuetxt               What you want the text to say for what someone should press to continue. If not
%                                   specified, defaults to what is in expt.instruct.space2continue
%
%   txtcolor                        The text color, as an RGB triplet (max 255). Defaults to white. 
%
%   wincolor                        The window background color, as an RGB triplet (max 255). Defaults to black. 
% 
%   key2continue                    The key that should be pressed to continue on. Defaults to space. 
% 
% Assumes that you use the spacebar to advance. Spits back a keyCode vector of all 0s so that no key is registered as
% pressed. 
% 
% Initiated RPK 2024-09-05

dbstop if error

%% 

if nargin < 2 || isempty(windowPointers)
    windowPointers = Screen('Windows'); 
end

nWindows = length(windowPointers); 

if nargin < 3 || isempty(winHeights)
    for w = 1:length(windowPointers)
        [~, height] = Screen('WindowSize', windowPointers(w)); 
        winHeights(w) = height; 
    end
end

if nargin < 4 || isempty(space2continuetxt), space2continuetxt = expt.instruct.space2continue; end

if nargin < 5 || isempty(txtcolor), txtcolor = [255 255 255]; end % default white

if nargin < 6 || isempty(wincolor), wincolor = [0 0 0]; end

if nargin < 7 || isempty(key2continue), key2continue = 'space'; end

%% 

for w = 1:nWindows
    Screen('TextFont', windowPointers(w), 'Arial');
    Screen('TextSize', windowPointers(w), 30);
end

%% 

continueKey = KbName(key2continue); 

%% Show pause text 
for w = 1:nWindows
    DrawFormattedText(windowPointers(w),expt.instruct.pausetxt,'center','center',txtcolor, expt.instruct.txtparams.wrapat(1)); % this is maybe a dumb fix... but I don't think it will break anything
    DrawFormattedText(windowPointers(w),space2continuetxt,'center',winHeights(w)*0.6,txtcolor, expt.instruct.txtparams.wrapat(1));
    Screen('Flip',windowPointers(w)); 
end

try
    DrawFormattedText(expt.ctrlWin, expt.ctrlInstruct.pausetxt, 'center', 'center', [255 255 255], expt.ctrlInstruct.txtparams.wrapat); 
    Screen('Flip', expt.ctrlWin); 
catch
end


%% Then wait for spacebar
pause(0.5); % Maybe it is triggering too fast for the lift up of the key? 
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

%% When done with pause, show resume
for w = 1:length(windowPointers)
    DrawFormattedText(windowPointers(w),expt.instruct.resumetxt,'center','center',txtcolor, expt.instruct.txtparams.wrapat(1));
    Screen('Flip',windowPointers(w)); 
end

try
    DrawFormattedText(expt.ctrlWin, expt.ctrlInstruct.resumetxt, 'center', 'center', [255 255 255], expt.ctrlInstruct.txtparams.wrapat); 
    Screen('Flip', expt.ctrlWin); 
catch
end

% Let the resume message linger 
WaitSecs(2); 

% Then make screen blank 
for w = 1:length(windowPointers)
    Screen('FillRect', windowPointers(w), wincolor);
    Screen('Flip',windowPointers(w)); 
end

try
    Screen('FillRect', expt.ctrlWin, [0 0 0]);
    Screen('Flip',expt.ctrlWin); 
catch
end

% And hold for a buffer so people can get ready 
WaitSecs(1.5); 
keyCode = zeros(1, 256); 

end