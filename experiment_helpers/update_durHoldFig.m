function [durHoldFig, expt] = update_durHoldFig(durHoldFig, durHoldCalc, expt, trial_index)

if strcmp(expt.conds{end}, 'pre')
    drow = trial_index; 
else
    drow = find([durHoldCalc.trialNo] == trial_index); % This might have to change... 
end


figure(durHoldFig); 
cla(durHoldFig); % clear axes to make sure that the axis doesn't accumulate data obscenely 
expt.durHold.h_scatAdjust = gscatter([durHoldCalc(1:drow).trialNo], [durHoldCalc(1:drow).availableDur] - [durHoldCalc(1:drow).warpAdjustment], ...
    {durHoldCalc(1:drow).includeLegend}', 'gg', '.x'); 
expt.durHold.h_scat = gscatter([durHoldCalc(1:drow).trialNo], [durHoldCalc(1:drow).availableDur], {durHoldCalc(1:drow).includeLegend}', 'br', '.x'); 
scatterIncludeIx = find(strcmp({durHoldCalc(1:drow).includeLegend}, 'Include'), 1, 'first'); 
scatterExcludeIx = find(strcmp({durHoldCalc(1:drow).includeLegend}, 'Exclude'), 1, 'first'); 

% Set group colors manually 
if scatterIncludeIx < scatterExcludeIx % If the first thing is include and both exclude and include exist
    expt.durHold.h_scat(1).Color = 'b'; 
    expt.durHold.h_scat(1).Marker = '.'; 
    expt.durHold.h_scat(2).Color = 'r'; 
    expt.durHold.h_scat(2).Marker = 'x'; 
    
    expt.durHold.h_scatAdjust(1).Marker = '.'; 
    expt.durHold.h_scatAdjust(2).Marker = 'x'; 
elseif scatterExcludeIx < scatterIncludeIx % If the first thing is exclude
    expt.durHold.h_scat(1).Color = 'r'; 
    expt.durHold.h_scat(1).Marker = 'x'; 
    expt.durHold.h_scat(2).Color = 'b'; 
    expt.durHold.h_scat(2).Marker = '.'; 
    
    expt.durHold.h_scatAdjust(1).Marker = 'x'; 
    expt.durHold.h_scatAdjust(2).Marker = '.'; 
elseif isempty(scatterExcludeIx)
    expt.durHold.h_scat(1).Color = 'b'; 
    expt.durHold.h_scat(1).Marker = '.'; 
    
    expt.durHold.h_scatAdjust(1).Marker = '.'; 
elseif isempty(scatterIncludeIx)
    expt.durHold.h_scat(1).Color = 'r'; 
    expt.durHold.h_scat(1).Marker = 'x'; 
    
    expt.durHold.h_scatAdjust(1).Marker = 'x'; 
end
xlim([min(durHoldCalc(drow).trialsUsed)-2 trial_index+1]); 
try delete(expt.durHold.h_includeline); catch; end
expt.durHold.h_includeline = xline(min([durHoldCalc(drow).trialsUsed]), 'LineStyle', '--'); % this could potentially be off if there are ever repeated trials
try delete(expt.durHold.h_holdline); catch; end