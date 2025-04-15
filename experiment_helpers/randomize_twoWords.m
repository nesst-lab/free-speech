function [allWords] = randomize_twoWords(nReps, repeatLimit)
% Function to get a slightly more controlled pseudorandomized list when you only have two stimuli (or two conditions) 
% 
% Inputs: 
%   nReps               the number of repetitions per word. E.g. if you enter 5, then allWords will be 10 items long. 
%
%   repeatLimit         the highest number of identical sequential items that you want. E.g. if you input 3, then you can get
%                       a sequence like 1 2 1 1 1 2 2 1 2 2 , but not 1 2 2 2 2 1 1 2 1 1 (because there are 4 2s in a row)
%
% Output
% 
%   allWords            just a vector of 1s and 2s that satisfies your conditions
% 
% 

dbstop if error

% Initiate
allWords = nan(1, nReps*2); 

drawCounts = [nReps nReps]; 
drawWeights = drawCounts/(nReps*2); 

%% Do the first "repeatLimit" trials 
% No need to check if you need to change draw weights until after you've set enough trials
allWords(1:repeatLimit) = randsample(2, repeatLimit, true); 

% Update the drawWeights
n1 = length(find(allWords == 1)); 
n2 = length(find(allWords == 2)); 

drawCounts = drawCounts - [n1 n2]; 
drawWeights = drawCounts/(nReps*2); 

%%

for w = (repeatLimit+1):length(allWords)
    % Get the last "repeat limit" trials (e.g., the last three trials) 
    lastRepeatIx = (w-1):-1:(w-repeatLimit); 
    lastRepeatWords = unique(allWords(lastRepeatIx)); 

    % If there is only one unique item in there
    if length(lastRepeatWords) == 1
        whichWordRepeated = lastRepeatWords; 

        % Then change the drawweights so they don't get selected again
        if whichWordRepeated == 1
            drawWeights = [0 1]; 
        else
            drawWeights = [1 0]; 
        end        
    end

    allWords(w) = randsample(2, 1, true, drawWeights); 

    % Reset the draw counts to get proper drawweights again 
    drawCounts(allWords(w)) = drawCounts(allWords(w))-1; % Take down the one that you just did
    drawWeights = drawCounts/(nReps*2); 
end


















end