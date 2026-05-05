function [] = aggregate_tempTrials(expt)
% 
% Standalone function to take all .mat files in a temp_trials folder and save them into a single data.mat structure
% 
% Initiated RPK 2026-05-04 to use in simonDelay2 (and other restart functions) 


%% Verify and set up temp trial path 
if isfield(expt,'dataPath')
    outputdir = expt.dataPath; 
else
    warning('Setting output directory to current directory: %s\n',pwd);
    outputdir = pwd;
end

trialdirname = 'temp_trials';
trialdir = fullfile(outputdir,trialdirname); 

repeatTrialdirname = 'repeat_trials'; 
repeatTrialdir = fullfile(outputdir,repeatTrialdirname); 
if ~exist(repeatTrialdir,'dir')
    mkdir(outputdir,repeatTrialdirname)
end

%% collect trials into one variable
alldata = struct;
fprintf('Processing trial data... \n')
for i = 1:expt.ntrials
    load(fullfile(trialdir,sprintf('%d.mat',i)))
    names = fieldnames(data);
    for j = 1:length(names)
        alldata(i).(names{j}) = data.(names{j});
    end
end

%% save data
fprintf('Saving data... ')
clear data
data = alldata;
save(fullfile(outputdir,'data.mat'), 'data')
fprintf('saved.\n')

%% collect repeated trials into one variable
repeatdata = struct;
repeatmats = dir(fullfile(repeatTrialdir,'*.mat')); 

if ~isempty(repeatmats)
    fprintf('Processing repeat data... \n')
    for i = 1:length(repeatmats)
        load(fullfile(repeatTrialdir,repeatmats(i).name))
        names = fieldnames(data);
        for j = 1:length(names)
            repeatdata(i).(names{j}) = data.(names{j});
        end
    end
    
    % save repeated data
    fprintf('Saving repeated trial data... ')
    clear data
    data = repeatdata;
    save(fullfile(outputdir,'repeat_data.mat'), 'repeatdata')
    fprintf('saved.\n') 
end

%%
% save expt
fprintf('Saving expt... ')
save(fullfile(outputdir,'expt.mat'), 'expt')
fprintf('saved.\n')

% remove temp trial directory
fprintf('Removing temp directory... ')
rmdir(trialdir,'s');
fprintf('done.\n')

% remove repeated temp trial directory
fprintf('Removing repeated temp directory... ')
rmdir(repeatTrialdir,'s');
fprintf('done.\n')

% clearing variables
clear outputdir
clear trialdir
clear trialdirname
clear repeatdata
clear repeatTrialdir
clear repeatTrialdirname
clear repeatmats