function [] = print_locationInLoop(target, newLineInterval, nIterations)
% Little function to print the number of, say, a trial in a loop of some sort, which automatically makes a new line after a
% particular interval. 
% 
% Input arguments: 
% 
%   target                  The number to print. Should be a whole number or a string
% 
%   newLineInterval         How often you want to print a new line, e.g. every 25 trials. Should be an integer. 
% 
%   nIterations             Optional input: how many times has this been called? Can be used if you are working in a loop
%                           that is defined over some vector that is not what you are printing. E.g. you are working only
%                           "bid" trials, so you might have trials 1 3 7 10 12 etc. In this case you may never hit the
%                           newLineInterval (e.g. if it is 25, and trial 25 was "bed") so you wouldn't print the new line.
%                           This argument will serve as the actual count. 
% 
%                           If empty, will assume it is the same as target if target is a number. If target is a string, will
%                           default to 1. 
% 
%  Output is just a fprintf statement.  
% 

if isnumeric(target)
    printThis = sprintf('%d', target); 
    if nargin < 3 || isempty(nIterations), nIterations = target; end
elseif ischar(target)
    printThis = target; 
    if nargin < 3 || isempty(nIterations), nIterations = 1; end
end

if ~mod(nIterations, newLineInterval)
    fprintf('%s\n', printThis); 
else
    fprintf('%s ', printThis); 
end



end