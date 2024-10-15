function [keyCode] = pause_trials_ptb(expt, windowPointers, winHeights, txtcolor, wincolor)
% A function to put pauses into PTB experiment trial loops 
% 
% Needs the following: 
% 
%   expt                            normal expt structure. Specifically, it needs the fields: 
%       instruct.pausetxt           - What you want to say during the pause
%       instruct.space2continue     - The text you use to tell people to hit spacebar to continue
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
% Assumes that you use the spacebar to advance. Spits back a keyCode vector of all 0s so that no key is registered as
% pressed. 
% 
% Initiated RPK 2024-09-05

dbstop if error

%% 

if nargin < 2 || isempty(windowPointers)
    windowPointers = Screen('Windows'); 
end

if nargin < 3 || isempty(winHeights)
    for w = 1:length(windowPointers)
        [~, height] = Screen('WindowSize', windowPointers(w)); 
        winHeights(w) = height; 
    end
end

if nargin < 4 || isempty(txtcolor), txtcolor = [255 255 255]; end % default white

if nargin < 5 || isempty(wincolor), wincolor = [0 0 0]; end

for w = 1:length(windowPointers)
    Screen('TextFont', windowPointers(w), 'Arial');
    Screen('TextSize', windowPointers(w), 30);
end

%% 
key2continue = 'space'; 
continueKey = KbName(key2continue); 

%% Show pause text 
for w = 1:length(windowPointers)
    DrawFormattedText(windowPointers(w),expt.instruct.pausetxt,'center','center',txtcolor, expt.instruct.txtparams.wrapat);
    DrawFormattedText(windowPointers(w),expt.instruct.space2continue,'center',winHeights(w)*0.6,txtcolor, expt.instruct.txtparams.wrapat);
    Screen('Flip',windowPointers(w)); 
end

%% Then wait for spacebar
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
    DrawFormattedText(windowPointers(w),expt.instruct.resumetxt,'center','center',txtcolor, expt.instruct.txtparams.wrapat);
    Screen('Flip',windowPointers(w)); 
end

% Let the resume message linger 
WaitSecs(2); 

% Then make screen blank 
for w = 1:length(windowPointers)
    Screen('FillRect', windowPointers(w), wincolor);
    Screen('Flip',windowPointers(w)); 
end

% And hold for a buffer so people can get ready 
WaitSecs(1.5); 
keyCode = zeros(1, 256); 

end