function [] = add_metronomeUserEvents(dataPath, trials, nEvents, isi)
% Takes in trial files from trials_signalOut and adds user events at defined intervals after the first one (which is provided
% in the trial file) 
% 
% nEvents is the number of ADDITIONAL events (so total number of metronome events - 1) 
% 
% Initiated RPK 2024-10-01 for expectDelays but should work for pacedVot as well 

dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(trials), trials = []; end
if nargin < 3 || isempty(nEvents), nEvents = 14; end % this is just the number for expectDelays
if nargin < 4 || isempty(isi), isi = 0.75; end % this is default for expectDelays

% Transform this into one isi per (additional) event 
if length(isi) ~= nEvents
    isi = repmat(isi, 1, nEvents); 
end

%%
% load in expt and data
load(fullfile(dataPath, 'expt.mat')); 
if isempty(trials)
    trials = 1:expt.ntrials; 
end
trialOutFolder = 'trials_signalOut'; 

%%

for t = trials
    trialFileName = [num2str(t) '.mat']; 
    try
        load(fullfile(dataPath, trialOutFolder, trialFileName)); 
    catch
        warning('No signalOut audioGUI file found for trial %d', t); 
        break; 
    end

    % Add in ticks 
    lastTickTime = max(trialparams.event_params.user_event_times); 
    nTicks = length(trialparams.event_params.user_event_times); 
    if nTicks > 1
        warning('More than one metronome tick already marked. Skipping trial %d.', t); 
        break; 
    end
    for m = 1:nEvents
        trialparams.event_params.user_event_times(nTicks + m) = lastTickTime + isi(m); 
        trialparams.event_params.user_event_names{nTicks + m} = ['uev' num2str(nTicks + m)]; 
        lastTickTime = lastTickTime + isi(m); 
    end
    save(fullfile(dataPath, trialOutFolder, trialFileName), 'sigmat', 'trialparams'); 

end




end