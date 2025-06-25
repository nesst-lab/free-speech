function [htracks,hsub] = plot_rawDurs(dataVals,segField,grouping,trialset,parent,expt)
%PLOT_RAWDURS           Plot the durations of segments of each trial. Used in check_timingDataVals
%   PLOT_RAWFMTTRACKS(DATAVALS,GROUPING,TRIALSET,PARENT) plots the first and
%   second formant tracks from each trial in TRIALSET in the figure or
%   panel defined by PARENT.  GROUPING defines the field in DATAVALS by
%   which data should be grouped; e.g. GROUPING = 'vowel' will create a
%   separate subplot for each vowel.

if nargin < 3 || isempty(grouping), grouping = 'word'; end
if nargin < 1 || isempty(dataVals)
    % RK: I don't like this but it should really never be called without inputs so I'll leave it for now. June 2025
    fprintf('Loading dataVals from current directory...')
    load dataVals.mat;
    fprintf(' done.\n')
    if exist(fullfile(cd,'expt.mat'),'file')
        fprintf('Loading expt from current directory...')
        load expt.mat;
        fprintf(' done.\n')
    end
end
if nargin < 4 || isempty(trialset), trialset = [dataVals.token]; end
if nargin < 5 || isempty(parent), h = figure('Units','normalized', 'Position',[.01 .25 .98 .5]); parent = h; end

%%

durColor = [0 0 1]; 
%%

groups = unique([dataVals.(grouping)]);

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
    [~,inds] =  ismember(trialset, [dataVals.token]);
    
    for i=inds % set of trials (jump, short, late, etc.) 
%         disp(i)
        if iscell(groupId)
            bInGroup = strcmp(dataVals(i).(grouping), groupId);
        else
            bInGroup = dataVals(i).(grouping) == groupId; 
        end
        if (~isfield(dataVals,'bExcl') || ~dataVals(i).bExcl) && bInGroup
            % Plot that trials' duration 
            htracks(g).dur(ihandle) = plot(dataVals(i).trial, dataVals(i).(segField),'Marker', 'o', 'LineStyle', 'none', ...
                'Color', durColor); 
            set(htracks(g).dur(ihandle),'Tag',num2str(dataVals(i).trial),'YdataSource',segField)
            hold on; 
            
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
    ylabel('duration (s)')
    box off;
    
    xlim([0 expt.ntrials]); 
    
    makeFig4Screen([],[],0);    
end


