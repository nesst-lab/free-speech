function bReversal = get_bReversal(previousAnswer, currentAnswer)
% NeSST LAB ONLY: if you opened the first file with this filename (either via 'open' or 'edit') and this came up, you need to
% CHANGE YOUR PATH so that the cerebDurJND folder is at the BOTTOM. This is a general function that is now housed in
% nesst-lab's fork of free-speech(/engines). 
% 
% Function that returns 1 or 0 based on previous answer and current answer. Can use this output to increment the tally of
% nReversals in the experiment. 
% 
% Note 1: This can be used with either a weighted staircase of a standard staircase, since reversals are defined the same way 
% (when staircase switches direction), either from plateau to rise, or rise to fall. RK is 95% sure this is the case. 
%
% Note 2: it is recommended to not use this on the very first trial, which should not be counted as a reversal, or on catch
% trials.  
% 
% Inputs: 
% 
%           previousAnswer:             The answer from current trial - 1. 
%
%           currentAnswer:              The answer from current trial. 
% 
%           Answer inputs should be given in something like bCorrect format, i.e. previousAnswer was correct and
%           currentAnswer was incorrect. This does NOT work if you input the ACTUAL ANSWERS from the keyboard/button input
%           (e.g., position 2, position 3 for an AAXA task). Currently handles numeric and strings
%
% Output:
%
%           bReversal:                  Whether you should increment reversal tally by 1
%
% Example:
% nReversals = nReversals + get_bReversal(1, 0); 
% 
% This would increment reversals by 1 since the two answers don't match (i.e., it is a peak or valley in the step function,
% if using a weighted staircase
% 
% Initiated RPK 2022-06-10 based on Gorilla function for timitate

dbstop if error

%%
if isnumeric(previousAnswer) && isnumeric(currentAnswer) 
    if previousAnswer == currentAnswer
        bReversal = 0; 
    else
        bReversal = 1; 
    end
    
elseif islogical(previousAnswer) && islogical(currentAnswer)
    if previousAnswer == currentAnswer
        bReversal = 0; 
    else
        bReversal = 1; 
    end

elseif ischar(previousAnswer) && ischar(currentAnswer)
    % Note that this also 
    if strcmp(previousAnswer, currentAnswer)
        bReversal = 0; 
    else
        bReversal = 1; 
    end
    
else
    warning('Unsupported answer types.')
end

end