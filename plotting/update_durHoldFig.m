function [durHoldFig, expt] = update_durHoldFig(durHoldFig, durHoldCalc, expt)
% Function that modularizes updating the durhold calculation figure during temporal perturbation studies
% 
% Takes in the figure, the durHoldCalc table, and expt
% 

dbstop if error

%% 

drow = find(~isnan([durHoldCalc.availableDur]), 1, 'last'); 
trial_index = durHoldCalc(drow).trialNo; 

%% 

figure(durHoldFig); 
cla(durHoldFig); % clear axes to make sure that the axis doesn't accumulate data obscenely 
expt.durHold.h_scatAdjust = gscatter([durHoldCalc(1:drow).trialNo], [durHoldCalc(1:drow).availableDur] - [durHoldCalc(1:drow).warpAdjustment], ...
        {durHoldCalc(1:drow).includeLegend}', 'gg', '.x'); 
expt.durHold.h_scat = gscatter([durHoldCalc(1:drow).trialNo], [durHoldCalc(1:drow).availableDur], {durHoldCalc(1:drow).includeLegend}', 'br', '.x'); 


%% Set group colors manually 

% Get the first include and the first exclude 
scatterIncludeIx = find(strcmp({durHoldCalc(1:drow).includeLegend}, 'Include'), 1, 'first'); 
scatterExcludeIx = find(strcmp({durHoldCalc(1:drow).includeLegend}, 'Exclude'), 1, 'first'); 

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
elseif isempty(scatterExcludeIx) % If no excludes, then only include
    expt.durHold.h_scat(1).Color = 'b'; 
    expt.durHold.h_scat(1).Marker = '.'; 
    
    expt.durHold.h_scatAdjust(1).Marker = '.'; 
elseif isempty(scatterIncludeIx) % If no includes, then only exclude
    expt.durHold.h_scat(1).Color = 'r'; 
    expt.durHold.h_scat(1).Marker = 'x'; 
    
    expt.durHold.h_scatAdjust(1).Marker = 'x'; 
end

%% Zoom in on current trials

xlim([min(durHoldCalc(drow).trialsUsed)-2 trial_index+1]); 

try delete(expt.durHold.h_holdline); catch; end
expt.durHold.h_holdline = yline(durHoldCalc(drow).nextDurHold, 'color', [0.1 0.8 0.4]); 


end