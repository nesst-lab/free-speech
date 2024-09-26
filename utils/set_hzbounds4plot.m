function [] = set_hzbounds4plot(dataPath, minimum, maximum, bCheckTrials)
% Dumb function to go in and set wave_viewer_params.plot_params.hzbounds4plot to some minimum and maximum. This is mostly for
% segmentation 
% 
% Inputs
% 
%   dataPath            where you will find the wave_viewer_params.mat file. Defaults to pwd
% 
%   minimum             the lowest Hz you want to see on your spectrogram. Defaults to 0. 
% 
%   maximum             the highest Hz you want to see on your spectrogram. Defaults to 8000. 
% 
%   bCheckTrials        If you've already looked at some trials, they'll have plotparams already defined. This will go
%                       through them, check if trialparams.plot_params exists, and if so then set hzbounds4plot to the
%                       max/min. Defaults to 1 (yes check)
% 
% Outputs
% 
%   wave_viewer_params.mat is saved with the new vector in hzbounds4plot.
% 
%   existing 1.mat files (etc.) that had hzbounds4plot specified already will be saved with the new value as well. 
% 
% Initiated 2023-06-19 RPK for taimComp segmentation purposes. Would have been good to have for all other s-segmentation
% things... 

dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = pwd; end
if nargin < 2 || isempty(minimum), minimum = 0; end
if nargin < 3 || isempty(maximum), maximum = 8000; end
if nargin < 4 || isempty(bCheckTrials), bCheckTrials = 1; end

%% Setting wave_viewer_params

fprintf('Setting Hz boundaries for plot in wave_viewer_params... '); 
load(fullfile(dataPath, 'wave_viewer_params.mat')); 
plot_params.hzbounds4plot = [minimum, maximum]; 
save(fullfile(dataPath, 'wave_viewer_params.mat'), 'plot_params', 'sigproc_params'); 
fprintf('Done.\n')


%% Check existing trials if bCheckTrials = 1

if bCheckTrials
    trialFolder = 'trials'; 
    fprintf('Checking existing trial files... '); 
    if exist(fullfile(dataPath, trialFolder))
        % Get list of trialFiles
        allFiles = dir(fullfile(dataPath, trialFolder)); 
        trialFiles = regexp({allFiles.name}, '[0-9].mat'); 
        trialFiles = {allFiles(find(~cellfun(@isempty, trialFiles))).name};                         %#ok<FNDSB> 
        nTrialFiles = length(trialFiles); 

        if nTrialFiles 
            fprintf('Updating trial '); 
            for i = 1:nTrialFiles
                fileName = trialFiles{i}; 
                namesplit = split(fileName, '.'); 
                trialNumber = namesplit{1};                 
                load(fullfile(dataPath, trialFolder, fileName)); 
                if exist('trialparams', 'var') && isfield(trialparams, 'plot_params')
                    print_locationInLoop(sprintf('%s ', trialNumber), 15, i); 
                    trialparams.plot_params.hzbounds4plot = [minimum maximum]; 
                    save(fullfile(dataPath, trialFolder, fileName), 'sigmat', 'trialparams'); 
                    clear sigmat
                    clear trialparams
                end % endif for check if plot_params is determined on this file

            end % endfor that opens up all the existing trial files
            fprintf('\nDone.\n'); 

        end % endif that checks for trial files even existing

    end % endif that checks for the trial folder even existing
end % endif for looking at trial files to begin with 

end % EOF