function [vuvData] = add_voiceUnvoiceData(dataPath, segs, bSave, trials)
% Function to get voice/unvoice percentage data from textgrids and put into dataVals-like table 
% 
% Inputs: 
% 
%   1. dataPath                 the participant path? This path will need to contain: 
%                                   - A folder called VUV with files like AudioData_1_VUV.TextGrid in it
%                                   - The VUV textgrids should have a segment ("phone") tier and a vuv tier 
% 
%   2. segs                     the specific segments (phones) you want to get voiced-unvoiced information from. Will default
%                               to all fricatives of English. This will be a match for ALL phones in a phrase that are a
%                               member of the list. So e.g. if you say "sue sipper" but you only want the second s, too bad
%                                   - Note: this is CASE INSENSITIVE 
%                                   - Should be a cell array of all the segments you want to examine, but will accept a
%                                   single string for a single segment as well (e.g. 's') 
% 
%   3. bSave                    Whether or not you want to save the file. Defaults to a save check. 
% 
% Output
% 
%   vuvData                     A structure array of information about voiced/unvoiced percentages for each segment. Will
%                               have participant ID, trial, list of segments (from the list match, as a cell array), their
%                               durations (as a vector), their VUV sequence (e.g., starts voiced, ends unvoiced = VU), the
%                               percentages of each voice/unvoiced portion, the start and end times of each voiced/unvoiced 
%                               portion, and the total voiced percentage, and total unvoiced percentage. 
%
% Initiated RPK 2024-11-14
% 

dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 2 || isempty(segs)
    segs = {'b' 's' 'z' 'sh' 'zh' 'f' 'v' 'dh' 'th' 'h'}; 
end

if ischar(segs), segs = {segs}; end % catch people just entering 's' instead of {'s'}

segs = [upper(segs) lower(segs)]; % So people can input either lower or upper case into the function

if nargin < 3 || isempty(bSave)
    bSave = savecheck(fullfile(dataPath, 'vuvData.mat')); 
end

%% Load in meta information 

load(fullfile(dataPath, 'expt.mat')); 
subj = expt.snum; 
ntrials = expt.ntrials; 

% Get number of files in VUV folder 
vuvPath = fullfile(dataPath, 'vuvTG'); 
vuvList = dir(vuvPath); 

vuvListNames = {vuvList.name}; 
nVuvFiles = sum(contains(vuvListNames, 'vuv', 'IgnoreCase', true)); % Get the number of trials with VUV in the name 
vuvFiles = {vuvListNames{find(contains(vuvListNames, 'vuv', 'IgnoreCase', true))}}; 

if nargin < 4 || isempty(trials), trials = 1:nVuvFiles; end


%% Loop through VUV files 

vuvData = []; 
for i = trials
    % INitialize everything as empty so that if you have a single-segment (zipper, sipper in isolation) you don't get
    % residual 1x2 cells
    targetSegs = {}; 
    segDurs = [];  
    vuv_seq = {}; 
    vuv_percs = {}; 
    vuv_starts = {}; 
    vPerc = []; 
    uPerc = []; 
    
    % vuvFileName = vuvFiles{i};
    trialNo = i; 
    vuvFileName = sprintf('AudioData_%d_VUV.TextGrid', trialNo); 
    splitFN = split(vuvFileName, '_'); 
    % trialNo = splitFN{2}; % It should always be in 2 position 
    % trialNo = str2double(trialNo); 
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
    segStarts = vuvTG.tier{1,phoneTierIx}.T1(targetIx); 
    segEnds = vuvTG.tier{1,phoneTierIx}.T2(targetIx); 
    segDurs = segEnds - segStarts; 

    % Get the VUV sequence for each segment 
    voicedIntervals = find(strcmpi(vuvLabels, 'v')); 
    unvoicedIntervals = find(strcmpi(vuvLabels, 'u')); 

    voicedTimes = []; 
    for v = 1:length(voicedIntervals)
        voicedInterval = voicedIntervals(v); 
        voicedTimes(v,:) = [vuvStarts(voicedInterval), vuvEnds(voicedInterval)]; 
    end

    unvoicedTimes = []; 
    for u = 1:length(unvoicedIntervals)
        unvoicedInterval = unvoicedIntervals(u); 
        unvoicedTimes(u,:) = [vuvStarts(unvoicedInterval), vuvEnds(unvoicedInterval)]; 
    end

    % Get the v/u status of the beginning of the segment 
    for s = 1:length(segStarts) % Loop through all your segments that are being measured in the trial (all fricatives)
        for v = 1:height(voicedTimes) % height of voicedTimes is the number of voiced intervals there are in the whole trial
            if segStarts(s) >= voicedTimes(v,1) && segStarts(s) < voicedTimes(v,2)
                % If the start of your segment is after the first voiced interval's start time, AND before its end time
                % (between the start and end of it), that means that your segment is starting voiced. So vu_segStart should
                % be labeled as v
                vu_segStart(s) = 'v'; 
                if segEnds(s) < voicedTimes(v,2) 
                    % If the end of the segment occurs before your voicing interval ends
                    % And you're not in the very last segment (in which case this situation should be impossible anyway I
                    % guess) 
                    vu_segStart_dur(s) = segEnds(s) - segStarts(s); 
                else
                    vu_segStart_dur(s) = voicedTimes(v,2) - segStarts(s); 
                end

                % Get the duration of the voiced component at the start. end of the voiced interval - start of the segment
                break; 
            end
        end

        for u = 1:height(unvoicedTimes)
            if segStarts(s) >= unvoicedTimes(u,1) && segStarts(s) < unvoicedTimes(u,2)
                vu_segStart(s) = 'u'; 
                if segEnds(s) < unvoicedTimes(u,2) 
                    % If the end of the segment occurs before your unvoicing interval ends
                    % And you're not in the very last segment (in which case this situation should be impossible anyway I
                    % guess) 
                    vu_segStart_dur(s) = segEnds(s) - segStarts(s); 
                else
                    vu_segStart_dur(s) = unvoicedTimes(u,2) - segStarts(s); 
                end
                break; 
            end
        end
    end

    % Get the v/u status of the end of the segment 
    for s = 1:length(segEnds)
        for v = 1:height(voicedTimes)
            if segEnds(s) >= voicedTimes(v,1) && segEnds(s) < voicedTimes(v,2)
                % If your seg end is after the start of a voiced time & before the end of that same voiced time 
                % then it ends in v also 
                vu_segEnd(s) = 'v'; 
                if segStarts(s) > voicedTimes(v,1) 
                    % If the end of the segment occurs before your voicing interval ends
                    % And you're not in the very last segment (in which case this situation should be impossible anyway I
                    % guess) 
                    vu_segEnd_dur(s) = segEnds(s) - segStarts(s); 
                else
                    vu_segEnd_dur(s) = segEnds(s) - voicedTimes(v,1); 
                end
                lastVU_startTime(s) = voicedTimes(v,1); 
                break; 
            end
        end

        for u = 1:height(unvoicedTimes)
            if segEnds(s) >= unvoicedTimes(u,1) && segEnds(s) < unvoicedTimes(u,2)
                vu_segEnd(s) = 'u'; 
                if segStarts(s) > unvoicedTimes(u,1) 
                    % If the end of the segment occurs before your voicing interval ends
                    % And you're not in the very last segment (in which case this situation should be impossible anyway I
                    % guess) 
                    vu_segEnd_dur(s) = segEnds(s) - segStarts(s); 
                else
                    vu_segEnd_dur(s) = segEnds(s) - unvoicedTimes(u,1); 
                end
                lastVU_startTime(s) = unvoicedTimes(u,1); 
                break; 
            end
        end
    end

    % Get things that happen between the beginning and the end
    for s = 1:length(segStarts) 
        vuvStarts_OI = find(vuvStarts > segStarts(s) & vuvEnds < segEnds(s)); % finding all the v/u labels that are within the segment time (start and end within the segment) 
        vuv_starts{s} = [segStarts(s) vuvStarts(vuvStarts_OI) lastVU_startTime(s)]; % start times for VUVs. Absolute start is the start of the segment. 
        % Then should be the starts of the VUVs that are fully contained. 
        % Then it should be the start time of the very last interval (which will most likely bleed off the edge)
        % vuvStarts_OI = vuvStarts_OI(1:end-1); 
        midvu_seq = [vuvLabels{vuvStarts_OI}]; 
        midvu_seq_durs = [vuvEnds(vuvStarts_OI) - vuvStarts(vuvStarts_OI)]; 

        if isempty(vuvStarts_OI) 
            % If you don't have anything between your start and end (i.e., you have a fully voiced or unvoiced seg OR you
            % have a vu/uv---nothing in the middle) 
            vuv_seq{s} = unique([vu_segStart(s) vu_segEnd(s)], 'stable'); 
            vuv_durs{s} = unique([vu_segStart_dur(s) vu_segEnd_dur(s)], 'stable'); 
        else
            vuv_seq{s} = [vu_segStart(s) lower(midvu_seq) vu_segEnd(s)];         
            vuv_durs{s} = [vu_segStart_dur(s) midvu_seq_durs vu_segEnd_dur(s)]; 
        end

        vuv_percs{s} = vuv_durs{s} / segDurs(s); 
        uints = find(vuv_seq{s} == 'u'); 
        vints = find(vuv_seq{s} == 'v'); 
        uPerc(s) = sum(vuv_percs{s}(uints)); 
        vPerc(s) = sum(vuv_percs{s}(vints)); 
    end

    % vuv table construction
    vuvData(i).subj = subj; 
    vuvData(i).trial = trialNo; 
    vuvData(i).targetSegs = targetSegs; 
    vuvData(i).segDurs = segDurs; 
    vuvData(i).vuv_sequence = vuv_seq; 
    vuvData(i).vuv_percs = vuv_percs; 
    vuvData(i).vuv_starts = vuv_starts; 
    vuvData(i).perc_voiced = vPerc; 
    vuvData(i).perc_unvoiced =  uPerc; 


end




%%
if bSave
    save(fullfile(dataPath, 'vuvData.mat'), 'vuvData'); 
end



end  % EOF
