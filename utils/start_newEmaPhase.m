function [] = start_newEmaPhase(sweepLen, bManual, address)

if nargin < 1 || isempty(sweepLen), sweepLen = 5; end
if nargin < 2 || isempty(bManual), bManual = 1; end
if nargin < 3 || isempty(address), address = '192.168.1.71'; end

if bManual
    fprintf('\n\n ** Now, press the sweep pedal once. Then hit SPACE. \n'); 
    pause
    fprintf('The "Active since" bar should now be red. Wait %d seconds...\n', sweepLen + 5); 
        for i = 1:sweepLen+5
            fprintf(' . .'); 
            pause(1); 
        end
        
    reinitiateRequest = sprintf('\n\n ** Now press the start button in the "active since" bar. Type INITIATED when you are done.\n\n');     
    askNChoiceQuestion(reinitiateRequest, {'initiated', 'INITIATED', 'Initiated'}, 0); 
    
else
    ToggleAG501(address); 
    fprintf('The "Active since" bar should now be red. Wait %d seconds...\n', sweepLen + 5); 
        for i = 1:sweepLen+5
            fprintf(' . .'); 
            pause(1); 
        end
        
    reinitiateRequest = sprintf('\n\n ** Now press the start button in the "active since" bar. Type INITIATED when you are done.\n\n');     
    askNChoiceQuestion(reinitiateRequest, {'initiated', 'INITIATED', 'Initiated'}, 0); 
    
end
    



end