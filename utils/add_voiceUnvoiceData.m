function [vuvData] = add_voiceUnvoiceData(dataPath, segs)
% Function to get voice/unvoice percentage data from textgrids and put into dataVals-like table 
% 
% Inputs: 
% 
%   dataPath                    the participant path? This path will need to contain: 
%                                   - A folder called VUV with files like AudioData_1_VUV.TextGrid in it
%                                   - The VUV textgrids should have a segment ("phone") tier and a vuv tier 
% 
%   segs                        the specific segments (phones) you want to get voiced-unvoiced information from. Will default
%                               to all fricatives of English. This will be a match for ALL phones in a phrase that are a
%                               member of the list. So e.g. if you say "sue sipper" but you only want the second s, too bad
%                                   - Note: this is CASE INSENSITIVE 
%                                   - Should be a cell array of all the segments you want to examine, but will accept a
%                                   single string for a single segment as well (e.g. 's') 
% 
% Output
% 
%   vuv_table                   A structure array of information about voiced/unvoiced percentages for each segment. Will
%                               have participant ID, trial, list of segments (from the list match, as a cell array), their
%                               durations (as a vector), their VUV sequence (e.g., starts voiced, ends unvoiced = VU), the
%                               percentages of each voice/unvoiced portion, and the start and end times of each voice/unvoice 
%                               portion
%
% Initiated RPK 2024-11-14
% 

dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(segs)
    segs = {'s' 'z' 'sh' 'zh' 'f' 'v' 'dh' 'th' 'h'}; 
end

if ischar(segs), segs = {segs}; end % catch people just entering 's' instead of {'s'}

segs = [upper(segs) lower(segs)]; % So people can input either lower or upper case into the function

%% Load in meta information 

load(fullfile(dataPath, 'expt.mat')); 
subj = expt.snum; 
ntrials = expt.ntrials; 

% Get number of files in VUV folder 
vuvPath = fullfile(dataPath, 'VUV'); 
vuvList = dir(vuvPath); 

vuvListNames = {vuvList.name}; 
nVuvFiles = sum(contains(vuvListNames, 'vuv', 'IgnoreCase', true)); % Get the number of trials with VUV in the name 
vuvFiles = {vuvListNames{find(contains(vuvListNames, 'vuv', 'IgnoreCase', true))}}; 


%% Loop through VUV files 

vuvData = []; 
for i = 1:nVuvFiles
    vuvFileName = vuvFiles{i}; 
    splitFN = split(vuvFileName, '_'); 
    trialNo = splitFN{2}; % It should always be in 2 position 
    trialNo = str2double(trialNo); 
    vuvTG = tgRead(fullfile(vuvPath, vuvFileName)); 

    % Find the tier that is called vuv (it doesn't matter what position it's in) 
    ntiers = length(vuvTG.tier); 
    for t = 1:ntiers
        tiername{t} = vuvTG.tier{1,t}.name; 
    end    
    vuvTierIx = find(strcmpi('vuv', tiername)); 
    phoneTierIx = find(strcmpi('phones', tiername)); 

    % Get the start/end times of the VUV tiers and if it's voiced or unvoiced
    nIntervals = length(vuvTG.tier{1,vuvTierIx}.Label); 
    vuvStarts = vuvTG.tier{1,vuvTierIx}.T1; 
    vuvEnds = vuvTG.tier{1,vuvTierIx}.T2; 
    vuvLabels = vuvTG.tier{1,vuvTierIx}.Label; 

    % Get the list of segs 
    segLabels = vuvTG.tier{1,phoneTierIx}.Label; 
    targetIx = []; 
    for s = 1:length(segLabels) 
        if ismember(segLabels{s}, segs)
            targetIx = [targetIx s]; 
        end
    end
    targetSegs = segLabels(targetIx); 

    % Get the start and end times of the target segment(s) 
    segStarts = vuvTG.tier{1,vuvTierIx}.T1(targetIx); 
    segEnds = vuvTG.tier{1,vuvTierIx}.T2(targetIx); 

    % Get the VUV sequence for each segment 








    % vuv table construction
    vuvData(i).subj = subj; 
    vuvData(i).trial = trialNo; 
    vuvData(i).targetSegs = targetSegs; 
    vuvData(i).segDurs = segEnds - segStarts; 
    % vuvData(i).vuv_sequence = 
    % vuvData(i).vuv_percs = 
    % vuvData(i).vuv_starts = 
    % vuvData(i).vuv_ends = 


end




%%




end
