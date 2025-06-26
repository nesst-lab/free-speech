function [htracks,hsub] = plot_rawDurs(dataValsIn, dataValsOut,segField,grouping,trialset,parent,expt)
%PLOT_RAWDURS           Plot the durations of segments of each trial. Used in check_timingDataVals
%   PLOT_RAWFMTTRACKS(DATAVALS,GROUPING,TRIALSET,PARENT) plots the first and
%   second formant tracks from each trial in TRIALSET in the figure or
%   panel defined by PARENT.  GROUPING defines the field in DATAVALS by
%   which data should be grouped; e.g. GROUPING = 'vowel' will create a
%   separate subplot for each vowel.

if nargin < 4 || isempty(grouping), grouping = 'word'; end
if nargin < 1 || isempty(dataValsIn)
    % RK: I don't like this but it should really never be called without inputs so I'll leave it for now. June 2025
    fprintf('Loading dataVals from current directory...')
    load dataVals_signalIn.mat;
    fprintf(' done.\n')
end
if nargin < 5 || isempty(trialset), trialset = [dataValsIn.trial]; end
if nargin < 6 || isempty(parent), h = figure('Units','normalized', 'Position',[.01 .25 .98 .5]); parent = h; end
if nargin < 7 || isempty(expt)
    if exist(fullfile(cd,'expt.mat'),'file')
        fprintf('Loading expt from current directory...')
        load expt.mat;
        fprintf(' done.\n')
    end
end

%%
plotcolors.dur = [25 180 85]./255; 
if contains(segField, 'Dur')
    plotcolors.pert = [0.5 0.2 0.6]; 
else
    plotcolors.pert = [30 170 200]./255; 
end



%%

groups = unique([dataValsIn.(grouping)]);

% RPK for non-compressed display with fewer words 
if length(groups) < 4
    nRows = length(groups); 
else
    nRows = 4;
end
for g = 1:length(groups)
    groupId = groups(g); 
    hsub(g) = subplot(nRows, ceil(length(groups)/nRows), g, 'Parent', parent);
%     hsub(g) = subplot(1,length(groups),g,'Parent',parent);
    % plot tracks and ends
    ihandle = 1;
    
    %collect the indices of dataVals where the trialset and token values
    %are the same
    [~,inds] =  ismember(trialset, [dataValsIn.trial]);
    
    for i=inds % set of trials (jump, short, late, etc.) 
%         disp(i)
        if iscell(groupId)
            bInGroup = strcmp(dataValsIn(i).(grouping), groupId);
        else
            bInGroup = dataValsIn(i).(grouping) == groupId; 
        end
        if (~isfield(dataValsIn,'bExcl') || ~dataValsIn(i).bExcl) && bInGroup
            % Plot that trials' duration 
            yyaxis left; 
            htracks(g).dur(ihandle) = plot(dataValsIn(i).trial, dataValsIn(i).(segField),'Marker', 'o', 'LineStyle', 'none', ...
                'MarkerFaceColor', plotcolors.dur, 'MarkerEdgeColor', plotcolors.dur - 0.05,'MarkerSize',5); 
            set(htracks(g).dur(ihandle),'Tag',num2str(dataValsIn(i).trial),'YdataSource',segField)
            hold on; 
            yyaxis right; 
            pert = dataValsOut(i).(segField) - dataValsIn(i).(segField); 
            htracks(g).pert(ihandle) = plot(dataValsIn(i).trial, pert, 'Marker', '^', 'LineStyle', 'none', ...
                'MarkerFaceColor', plotcolors.pert, 'MarkerEdgeColor', plotcolors.pert - 0.05,'MarkerSize',5); 
            set(htracks(g).pert(ihandle),'Tag',num2str(dataValsIn(i).trial),'YdataSource',segField)
            
            ihandle = ihandle+1;
        end
    end
    
    % figure labels
    if exist('expt','var')
        groupnames = expt.(sprintf('%ss',grouping));
        titlesuffix = sprintf(': %s',groupnames{groupId});
    else
        titlesuffix = [];
    end
    
    title(sprintf('%s %d%s',grouping,groupId,titlesuffix))
    xlabel('trial')
    
    yyaxis left
    ax = gca; 
    ylabel('duration (s)', 'Color', plotcolors.dur); 
    ax.YColor = plotcolors.dur; 
    ylim([min([dataValsIn(inds).(segField)]) - 0.03 max([dataValsIn(inds).(segField)]) + 0.03]); 
    
    yyaxis right
    ax = gca; 
    if contains(segField, 'Dur')
        ylabel('perturbation (s)', 'Color', plotcolors.pert); 
    else
        ylabel('lag (s)', 'Color', plotcolors.pert);
    end
    ax.YColor = plotcolors.pert; 
    ylim([min(expt.pertMag) - 0.01 max(expt.pertMag) + 0.05]); 
    box off;
    
    xlim([0 expt.ntrials]); 
    
    makeFig4Screen([],[],0);    
end


