function [htracks,hsub] = plot_rawDurs(dataValsIn, dataValsOut,pertField,grouping,trialset,parent,expt)
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
% segField will come in as either ehDur or ehStart_time (or whatever seg)
plotcolors.dur = [25 180 85]./255; 
if contains(pertField, 'Dur')
    plotcolors.pert = [0.5 0.2 0.6]; 
    segSplit = strsplit(pertField, 'Dur'); 
else
    plotcolors.pert = [30 170 200]./255; 
    segSplit = strsplit(pertField, 'Start_time'); 
end

% This combines just the seg part with the actual duration 
durField = [segSplit{1} 'Dur']; 



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
    pert = 0; % So the min/max works ylim works 
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
            htracks(g).dur(ihandle) = plot(dataValsIn(i).trial, dataValsIn(i).(durField),'Marker', 'o', 'LineStyle', 'none', ...
                'MarkerFaceColor', plotcolors.dur, 'MarkerEdgeColor', plotcolors.dur - 0.05,'MarkerSize',5); 
            set(htracks(g).dur(ihandle),'Tag',num2str(dataValsIn(i).trial),'YdataSource',durField)
            hold on; 
            yyaxis right; 
            pert(i) = dataValsOut(i).(pertField) - dataValsIn(i).(pertField); 
            htracks(g).pert(ihandle) = plot(dataValsIn(i).trial, pert(i), 'Marker', '^', 'LineStyle', 'none', ...
                'MarkerFaceColor', plotcolors.pert, 'MarkerEdgeColor', plotcolors.pert - 0.05,'MarkerSize',5); 
            set(htracks(g).pert(ihandle),'Tag',num2str(dataValsIn(i).trial),'YdataSource',pertField)
            
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
    try
        ylim([min([dataValsIn(inds).(durField)]) - 0.03 max([dataValsIn(inds).(durField)]) + 0.03]); 
    catch
        warning('Please report the data and trial number %d to Robin for debugging', i); 
    end
    
    yyaxis right
    ax = gca; 
    if contains(pertField, 'Dur')
        ylabel('perturbation (s)', 'Color', plotcolors.pert); 
    else
        ylabel('lag (s)', 'Color', plotcolors.pert);
    end
    ax.YColor = plotcolors.pert; 
    try 
        ylim([min(pert) - 0.01 max(pert) + 0.05]); 
    catch
        warning('Please report the data and trial number %d to Robin for debugging', i); 
    end
    box off;
    
    xlim([0 expt.ntrials]); 
    
    makeFig4Screen([],[],0);    
end


