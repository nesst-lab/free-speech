function [] = gen_uevsFromOsts(dataPath, trials, statuses)





load(fullfile(dataPath, 'data.mat')); 
load(fullfile(dataPath, 'expt.mat')); 

trackingFileLoc = expt.trackingFileLoc; 
trackingFileName = expt.trackingFileName; 

ostInfo = get_ost(trackingFileLoc, trackingFileName, 'full'); 

if isempty(statuses)
    for o = 1:length(ostInfo)
        statuses(o) = ostInfo{o}{1}; 
    end
end


threeParamHeurs = {'INTENSITY_AND_RATIO_ABOVE_THRESH', 'INTENSITY_AND_RATIO_BELOW_THRESH'}; 
firstParamDurHeurs = {'ELAPSED_TIME', 'POS_INTENSITY_SLOPE_STRETCH', 'NEG_INTENSITY_SLOPE_STRETCH_SPAN'}; 











end