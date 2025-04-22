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
% This uses draw weights + randsample to get a sequence. 
% 
% Draw weights are originally set at 50/50: [nReps nReps]/(total length of sequence) 
% 
% Weights change after each random draw. So, e.g., if the first item is a 1, the new weights will be [nReps-1 nReps]/(total
% length of sequence - 1) 
% 
% If the last repeatLimit trials are all the same item, then the draw weight for that item drops to 0, so it's a 100% chance
% that the other item will be selected at that time. Then the draw weights reset to normal. 
% 
% This randomization function is allowed to attempt making a sequence 100*sequence length times. If it fails out after that,
% then it'll give you the last attempt + random sequence at the end of the remaining 1s and 2s. As of 4/21 I (RK) have not
% been able to figure out a combination of nReps and repeatLimit that makes the number of attempts surpass 2. 
% 
% Initiated RPK 2025-04-18
% 

dbstop if error
rng('shuffle');

if repeatLimit == 1
    warning('You are requesting a strictly alternating sequence.'); 
end

%% Initiate
allWords = nan(1, nReps*2); 
drawCounts = [nReps nReps];
allowedAttempts = 100*length(allWords); 

a = 1; 
while a < allowedAttempts && sum(isnan(allWords)) 
    % While you're still under the number of allowed attempts, and while there are still nans in the string
    % (If you do this successfully, when you get out of the for loop, you'll have no nans, so you'll break out) 
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
    
        try
            % attempt to get a random draw. 
            allWords(w) = randsample(2, 1, true, drawWeights); 
        
            % Reset the draw counts to get proper drawweights again 
            drawCounts(allWords(w)) = drawCounts(allWords(w))-1; % Take down the one that you just did
            drawWeights = drawCounts/(nReps*2); 
        catch
            % You might error---e.g. if you happened to draw a poor sequence and now you're stuck 
            a = a+1; % increment the number of attempts
            
            if a > allowedAttempts
                % RK note: I haven't tested this, because with all the combinations of reps and repeatLimit that I've tried,
                % I've only gotten to 2 attempts. This is NOT like the randomizing function for taimComp, apparently 
                % If you've tried too many times, then patch it up 
                nanix = find(isnan(allWords)); 
                % Get the number of times you've had word 1 and 2
                n1s = length(find(allWords == 1)); 
                n2s = length(find(allWords == 2)); 

                % Make a little vector with the remaining ones 
                remainingWords = [1*ones(1, nReps-n1s) 2*ones(1, nReps-n2s)]; 

                % Then shuffle them
                rand12ix = randsample(length(remainingWords), length(remainingWords)); 
                rand12 = remainingWords(rand12ix); 

                % Then put them into allWords
                allWords(nanix) = rand12; 
                warning('Too many attempts. Using last sequence + random ending.'); 
            else
                % Reset allWords to nans
                allWords = nan(1, nReps*2); 
                drawCounts = [nReps nReps]; % And reset your draw counts
                % Then break out of the for loop 
            end
            break; % Get outta the for and go back to the beginning
        end %end try
    end %end for
end %end while


end % EOF