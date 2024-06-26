function [expt] = run_forcedChoice_engine(expt)
% General purpose engine for a forced choice task, using Matlab alone (so note that if you're really interested in reaction
% time, you should alter this to use psychtoolbox or something else instead) 
% 
% Requires the following fields in the input expt: 
% 
% Experiment information
%       steps, listSteps, allSteps  As per smng convention, 
%                                       steps = the unique steps that are being used, e.g. if 110, 120, 130 ms then [110 120
%                                       130]
%                                       listSteps = the list of steps being used in each trial. E.g. [120 130 110 110 130
%                                       120] if there are 6 trials
%                                       allSteps = the index of steps being used in each trial. E.g. [2 3 1 1 3 2]                                      
% 
% Soundfile information
%       soundfileDir                where to find the sound files        
% 
%       soundfilePrefix             everything in a soundfile name that precedes the number. E.g. if the soundfiles are
%                                   'SSEd_step1.wav' then it is 'SSEd_step'
%
%       soundfileSuffix             everything in a soundfile name that follows the number, INCLUDING the file extension.
%                                   E.g. if the soundfiles are 'SSEd_step1.wav' then it is '.wav'. If it is 'moB_150ms.wav'
%                                   then it is 'ms.wav'
% 
% Information on the choices the participant can make
%       words                       The two words that are the available choices.  
%
%       answerOrder                 A cell array where the first item is the left answer and the second is the right answer.
%                                   This order most likely should be determined by a cbPermutation file in the _expt
% 
%       leftKey                     A string that is the name of the keyboard key participants hit for the choice appearing
%                                   on the LEFT of the screen. E.g. 'f' 
%
%       rightKey                    A string that is the name of the keyboard key participants hit for the choice appearing
%                                   on the RIGHT of the screen. E.g. 'j'
% 
% Instruction texts (in the field instruct in expt)
%       introtxt                    Basic instructions on what the task is ("will hear sound files, say which word you
%                                   heard...")
% 
%       reassurancetxt              Extended instructions to reassure people that sometimes the words will not sound clearly
%                                   like one word or the other, and they should make their best guess 
% 
%       leftDiagram                 A diagram of some sort that indicates how to respond with the word on the left
% 
%       rightDiagram                A diagram of some sort that indicates how to respond with the word on the right
% 
% 
% Outputs: 
%       data                        A structure with information about each trial in each index. 
% 
%       responseMatrix              A matrix with columns being steps and rows being repetitions of each step. Cells are a 1
%                                   if the participant responded with the first word in expt.words, and a 0 if they responded
%                                   with the second word. This is saved to dataPath at the end of the script. 
% 
% 
% Initiated RPK 2022-06-23 based on measureBound



%% Set up datapath
if ~exist(expt.dataPath, 'dir'), mkdir(expt.dataPath); end
save(fullfile(expt.dataPath, 'expt.mat'), 'expt'); 


%% Generate player objects for each stimulus

% Get audio playback information 
info = audiodevinfo; 
focusriteIx = find(contains({info.output.Name}, 'Focusrite')); 
focusriteID = info.output(focusriteIx).ID; 

for i = 1:length(expt.steps)
    step = expt.steps{i}; 
    stimSoundFN = [expt.soundfilePrefix step expt.soundfileSuffix]; 
    [soundY, soundFs] = audioread(fullfile(expt.soundfileDir, stimSoundFN)); 
    stimAudio(i).player = audioplayer(soundY, soundFs, 16, focusriteID);    
end


%% Initialize screens and instructions
h_fig = setup_exptFigs;
get_figinds_audapter; % names figs: stim = 1, ctrl = 2, dup = 3;
h_sub = get_subfigs_audapter(h_fig(ctrl));

% Instructions 
figure(h_fig(stim))
h_instruct(1) = text(0.5, 0.5, expt.instruct.introtxt, expt.instruct.txtparams);
h_instruct(2) = text(0.25, 0.55, expt.instruct.leftDiagram, expt.instruct.txtparams);
h_instruct(3) = text(0.75, 0.55, expt.instruct.rightDiagram, expt.instruct.txtparams);
CloneFig(stim, dup); 
% NB: I am currently doing it this way rather than with draw_exptText because there are many lines of text and text+clone for
% each line really slows down the display, and displays it visibly sequentially. plain text with a clone call after does not
% do that. 

pause
delete_exptText(h_fig,h_instruct)

% Reassurances 
figure(h_fig(stim))
h_reassure(1) = draw_exptText(h_fig, 0.5, 0.5, expt.instruct.reassurancetxt, expt.instruct.txtparams);
pause
delete_exptText(h_fig, h_reassure); 

%% Set up whole data structure so you can build/save faster
data(expt.ntrials).subj = expt.snum; 
data(expt.ntrials).trial = expt.ntrials; % I just don't want stepSize to be the first column... 
save(fullfile(expt.dataPath, 'data.mat'), 'data'); 

leftAnswer = expt.answerOrder{1}; 
rightAnswer = expt.answerOrder{2}; 

responseMatrix = zeros(expt.nReps, expt.nSteps); % The response matrix. Starts as all 0s. 
trackReps = zeros(1, expt.nSteps); % Keeping track of the number of repetitions for each stimulus
%% Trial loop
for itrial = 1:expt.ntrials
    
    % Meta
    data(itrial).subj = expt.snum;                        % Participant code 
    data(itrial).trial = itrial;                            % Trial number
    
    % Trial information
    trialStep = expt.listSteps(itrial); 
    data(itrial).step = trialStep; 
    
    % Step information 
    stepNumber = expt.allSteps(itrial); 
    stepRep = trackReps(stepNumber) + 1; % This starts at 0, so it should increment to 1 right before you hear it for the first time
    data(itrial).stepRep = stepRep; % Record that information in the data matrix 
    
    %% Sound section
    h_fixation = draw_exptText(h_fig, 0.5, 0.5, '+','HorizontalAlignment','center','Color','w','FontSize',80);
    play(stimAudio(stepNumber).player); 
    soundDur = stimAudio(stepNumber).player.TotalSamples / stimAudio(stepNumber).player.SampleRate; 
    pause(soundDur); % Wait to display stuff until after sound is done

    
    %% Response section
    % Show buttons
    % Left word
    delete_exptText(h_fig, h_fixation); 
    figure(h_fig(stim)); 
    h_reminder(1) = text(0.25, 0.55, expt.instruct.leftDiagram, expt.instruct.txtparams);
    h_reminder(2) = text(0.75, 0.55, expt.instruct.rightDiagram, expt.instruct.txtparams);
    CloneFig(stim, dup); 
    
    % Get response 
    response = {};
    tic; 
    while isempty(response)
        w = waitforbuttonpress;
        if w
           subjInput = get(gcf, 'CurrentCharacter');
        end
        if strcmp(subjInput, expt.leftKey) 
            response = leftAnswer; 
        elseif strcmp(subjInput, expt.rightKey) 
            response = rightAnswer; 
        else
            h_badResponse = draw_exptText(h_fig, 0.5, 0.3, sprintf('Invalid Response. Please type %s or %s. ', upper(expt.leftKey), upper(expt.rightKey)),...
                expt.instruct.txtparams);
        end
    end
    
    % Delete text 
    delete_exptText(h_fig, h_reminder); 
    if exist('h_badResponse','var')
        delete_exptText(h_fig,h_badResponse)
    end
    rt = toc; 
    
    %% Fill in data structures 
    data(itrial).response = response; 
    data(itrial).rt = rt; % Very rough reaction time, given that it is Matlab
    
    isWord1 = double(strcmp(response, expt.words{1})); % Check if the response is the same as Word 1 
    responseMatrix(stepRep, stepNumber) = isWord1; % Fill in the matrix with 1/0 (1 = response was Word 1, 0 = response was Word 2) 
    trackReps(stepNumber) = stepRep; % Increment how many times this stimulus has been heard in the tracking matrix 
    
    % Write response to file (response matrix can be reconstructed as long as this is saved) 
    save(fullfile(expt.dataPath, 'data.mat'), 'data'); 
    interstimJitter = expt.timing.interstimdur + rand*expt.timing.interstimjitter;  
    pause(interstimJitter); 
    
    %% Check for pause 
    if itrial == expt.ntrials
        breaktext = sprintf('Thank you!\n\nPlease wait.');
        draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
        pause(3);
    elseif any(expt.breakTrials == itrial)
        breaktext = sprintf('Time for a break!\n%d of %d trials done.\n\nPress the space bar to continue.',itrial,expt.ntrials);
        h_break = draw_exptText(h_fig,.5,.5,breaktext,expt.instruct.txtparams);
        pause
        delete_exptText(h_fig,h_break)
        pause(1);
    end
    
end

% Save response matrix 
save(fullfile(expt.dataPath, 'responseMatrix.mat'), 'responseMatrix'); 

try
    close(h_fig)
catch
end

end