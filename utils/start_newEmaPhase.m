function [] = start_newEmaPhase(sweepLen)

if nargin < 1 || isempty(sweepLen), sweepLen = 5; end

fprintf('\n\n ** Now, press the sweep pedal once. Then hit SPACE. \n'); 
pause
fprintf('The "Active since" bar should now be red. Wait %d seconds...\n', sweepLen + 5); 
    for i = 1:sweepLen+5
        fprintf(' . .'); 
        pause(1); 
    end

reinitiateRequest = sprintf('\n\n ** Now press the start button in the "active since" bar. Type INITIATED when you are done.\n\n');     
askNChoiceQuestion(reinitiateRequest, {'initiated', 'INITIATED', 'Initiated'}, 0); 

end