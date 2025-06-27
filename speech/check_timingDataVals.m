function [] = check_timingDataVals(dataPath, show_seg, errorParams, dataValsFunction, varargin)
% Function to generally check that: 
%   1. Hand correction is in the realm of correct
%   2. Duration perturbations are what you were expecting
%   3. Lags are what you were expecting
% 
% This will show you a figure of: 
%   1. the durations of the specified segment in signalIn, organized by trial
%   2. the difference in duration between signalIn and signalOut for that segment
%   3. the onset lag between signalIn and signalOut for that segment 
% 
% You will be able to click on a specific trial and go out to audioGUI of that trial (signalIn or signalOut)
% 
% There may be an option to regenerate dataVals
% 
% Inputs: 
% 
%       dataPath                the data path where there is a data.mat, expt.mat, dataVals.mat, and dataVals_signalOut.mat. 
%                               Defaults to pwd
% 
%       show_seg                the NAME of the segment that you are checking. This is whatever the fieldname "prefix" is in
%                               dataVals. e.g. if you have 'eDur' 'eStart_time' then you should put in 'e'. This is not
%                               necessarily the same as what it is called in MFA/user events! 
% 
%       errorParams             a structure array with possible fields: shortThresh, longThresh, jumpThresh, lateThresh_ratio,
%                               lateThresh_absolute, earlyThresh_absolute. These will let you override the defaults. 
% 
%       dataValsFunction        the function that YOUR experiment uses to generate timing dataVals. Provide this as a
%                               function call: @gen_dataVals_tramTransfer, for example. If there is not a specific
%                               gen_dataVals for your experiment, this will default to gen_timingDataVals, which works fine
%                               for all basic temporal adaptation studies. 
% 
%       varargin                varargin is specifically arguments that you might feed into the dataValsFunction. Even more
%                               specifically, it is input arguments 4+; the first three arguments are known by
%                               check_timingDataVals and will be automatically fed in. For example, if you are using the
%                               generic gen_timingDataVals, you might include: 
%                               - 'words' as the first varargin, to denote that you want to use expt.words instead of
%                               expt.stimulusText (to acquire the arpabet version of each trial). This is argument 4 in
%                               gen_timingDataVals. 
%                               - {'eh' 's' 't'} as the second varargin, to denote that you only want to get timing
%                               information about eh, s, and t, and NOT the rest of the segments in the trial. This is
%                               argument 5 in gen_timningDataVals. 
%                               - note that you MUST PUT ARGUMENTS IN THE CORRECT ORDER FOR THE FUNCTION. So, if you wanted
%                               to call gen_timingDataVals with stimulusText but change the segments, your call to
%                               check_timingDataVals would be check_timingDataVals(dataPath, 'eh', [3], [4], [5], {'eh' 's'
%                               't'}). 3 is errorParams, which you could leave empty; 4 is the dataVals function which you
%                               can also leave empty, and 5 is the textField argument for gen_timingDataVals, which you can
%                               leave empty as well. 
%       
% Outputs: 
% 
%       ? 
% 
% Initiated RPK 2025-06-25 for deftAcoustic. Previous experiments will not necessarily work with this 
% 
% 

dbstop if error

if nargin < 1 || isempty(dataPath), dataPath = cd; end
if nargin < 3 || isempty(errorParams), errorParams = struct; end
if nargin < 4 || isempty(dataValsFunction), dataValsFunction = @gen_timingDataVals; end
% if nargin < 5 || isempty(textField), textField = 'stimulusText'; end
% if nargin < 6 || isempty(gen_segs), gen_segs = {'all'}; end

%% Load in various data structures

if ~exist(fullfile(dataPath, 'dataVals_signalIn.mat'), 'file')
    dataValsFunction([], 'signalIn', [], varargin{1:end});     
end
load(fullfile(dataPath, 'dataVals_signalIn.mat')); 
dataValsIn = dataVals; 
clear dataVals; 

if ~exist(fullfile(dataPath, 'dataVals_signalOut.mat'), 'file')
    dataValsFunction([], 'signalOut', [], varargin{1:end}); 
end
load(fullfile(dataPath, 'dataVals_signalOut.mat')); 
dataValsOut = dataVals; 
clear dataVals; 

load(fullfile(dataPath, 'expt.mat')); 


%% Set up the fieldnames you'll be looking for in dataVals

segFields.dur = [show_seg 'Dur']; 
segFields.lag = [show_seg 'Start_time']; 


%% Set up error parameters

% config errorParams
defaultParams.shortThresh = 0.05; % less than 50 ms 
defaultParams.longThresh = 0.5; %longer than 1 second
defaultParams.jumpThresh = 200; %in Hz, upper limit for sample-to-sample change to detect jumpTrials in F1 trajectory
defaultParams.lateThresh_ratio = 0.96; % acceptable endpoint ratio for speech before trial ends "too late"
defaultParams.lateThresh_absolute = 1.5; % acceptable endpoint in seconds for speech before trial ends "too late". Only used as fallback if trial duration not available.
defaultParams.earlyThresh_absolute = 0.05; 
errorParams = set_missingFields(errorParams, defaultParams, 0);

%% Set up GUI 

h_tdv = figure('Name', 'Check Timing Data Vals', 'Units', 'Normalized', 'Position', [0.1 0.1 0.85 0.8]); % , 'CloseRequestFcn', @save_exit
% set(h_tdv,'DeleteFcn',@delete_func); % Keep delete_func, which just calls the save and exit prompt

UserData = guihandles(h_tdv);
UserData.dataPath = dataPath;
UserData.f = h_tdv;
UserData.errorParams = errorParams; 
UserData.xPosMax = 0.975;
UserData.expt = expt; 
UserData.dataValsIn = dataValsIn; 
UserData.dataValsOut = dataValsOut; 
UserData.segFields = segFields; 
UserData.dataValsFunction = dataValsFunction; 
UserData.varargin = varargin; 

colors.pert = [0.5 0.2 0.6]; 
colors.dur = [25 180 85]./255; 
colors.lag = [30 170 200]./255; 
colors.unselected = [0.9 0.9 0.9]; 
UserData.colors = colors; 

% create warning text area
warnPanelXPos = 0.575;
warnPanelXSpan = 0.125;
warnPanelYSpan = 0.11;
warnPanelYPos = UserData.xPosMax-warnPanelYSpan;
warnPanelPos = [warnPanelXPos warnPanelYPos warnPanelXSpan warnPanelYSpan];
UserData.warnPanel= uipanel(UserData.f,'Units','Normalized','Position',...
            warnPanelPos,'Title',' alerts ',...
            'Tag','warn_panel','TitlePosition','CenterTop',...
            'FontSize',0.02,'FontUnits','Normalized','Visible','on');

UserData.warnText = uicontrol(UserData.warnPanel,'style','text',...
            'String',[],...
            'Units','Normalized','Position',[.1 .1 .8 .8],...
            'FontUnits','Normalized','FontSize',.3);
        
UserData.errors = get_dataVals_errors(UserData,dataValsIn,segFields);

%%

plotPanelXPos = 0.175;
plotPanelXSpan = 1 - 0.025 - plotPanelXPos;
plotPanelYPos = UserData.xPosMax - 0.95;
plotPanelYSpan = 0.815;
plotPanelPos = [plotPanelXPos plotPanelYPos plotPanelXSpan plotPanelYSpan];
UserData.plotPanel = uipanel(UserData.f,'Units','Normalized','Position',...
            plotPanelPos,...
            'Tag','formant_plots','Visible','on');
 % create action buttons
actionPanelXPos = 0.725;
actionPanelXSpan = 0.25;
actionPanelYSpan = 0.11;
actionPanelYPos = UserData.xPosMax-actionPanelYSpan;
actionPanelPos = [actionPanelXPos actionPanelYPos actionPanelXSpan actionPanelYSpan]; 
UserData.actionPanel = uipanel(UserData.f,'Units','Normalized','Position',...
            actionPanelPos,'Title',' actions ',...
            'Tag','trial_sel','TitlePosition','CenterTop',...
            'FontSize',0.02,'FontUnits','Normalized','Visible','on');

trialTypes = {'launch_GUI', 'reload_dataVals'};
nActionTypes = length(trialTypes);

actionButtonYSep = 0.05;
actionButtonXSep = 0.05;
actionButtonYSpan = 1 - 2*actionButtonYSep;
actionButtonYPos = actionButtonYSep;
actionButtonXSpan = (1 - actionButtonYSep*(nActionTypes+1))/nActionTypes;
for iButton = 1: nActionTypes
    ABname = strcat('AB_', trialTypes(iButton));
    actionButtonXPos = actionButtonXSep*iButton + actionButtonXSpan*(iButton-1);
    actionButtonPos = [actionButtonXPos actionButtonYPos actionButtonXSpan actionButtonYSpan];
    UserData.(ABname{1}) = uicontrol(UserData.actionPanel,...
        'Style','pushbutton','String',trialTypes(iButton),...
        'Units','Normalized','Position',actionButtonPos,...
        'FontUnits','Normalized','FontSize',0.3);
end
set(UserData.AB_launch_GUI,'CallBack',@launch_GUI)
set(UserData.AB_reload_dataVals,'CallBack',@reload_dataVals)

%generate other buttons
UserData = generate_menus(UserData);

guidata(h_tdv,UserData);

end % End of main GUI

%% Start internal functions
function save_exit(hObject,eventdata)
    delete(h_tdv); 
end


function delete_func(src,event)
    viewer_end_state = 1; 
end

function UserData = generate_menus(UserData)
    % create error type buttons
    errorPanelXPos = 0.025;
    errorPanelXSpan = 0.125;
    errorPanelYSpan = 0.775;
    errorPanelYPos = UserData.xPosMax - errorPanelYSpan;
    errorPanelPos = [errorPanelXPos errorPanelYPos errorPanelXSpan errorPanelYSpan]; 
    UserData.errorPanel = uibuttongroup(UserData.f,'Units','Normalized','Position',...
                errorPanelPos,'Title',' error types ',...
                'Tag','error_types','TitlePosition','CenterTop',...
                'FontSize',0.02,'FontUnits','Normalized','Visible','on',...
                'SelectedObject',[],'SelectionChangedFcn',@update_plots);

    errorTypes = fieldnames(UserData.errors);
    nErrorTypes = length(errorTypes);

    errorButtonYSep = 0.01;
    errorButtonXSep = 0.05;
    errorButtonXSpan = 1 - 2*errorButtonXSep;
    errorButtonXPos = errorButtonXSep;
    errorButtonYSpan = (1 - errorButtonYSep*(nErrorTypes+1))/nErrorTypes;
    for iButton = 1: nErrorTypes
        EBname = strcat('EB_', errorTypes(iButton));
        errorButtonYPos = 1 - errorButtonYSep*iButton - errorButtonYSpan*iButton;
        errorButtonPos = [errorButtonXPos errorButtonYPos errorButtonXSpan errorButtonYSpan];
        UserData.(EBname{1}) = uicontrol(UserData.errorPanel,...
            'Style','togglebutton','String',errorTypes(iButton),...
            'Units','Normalized','Position',errorButtonPos,...
            'FontUnits','Normalized','FontSize',0.3);
        if ~isempty(UserData.errors.(errorTypes{iButton}))
            if strcmp(errorTypes{iButton},'goodTrials')
                set(UserData.(EBname{1}),'ForegroundColor',[0 0.7 0]);
            else
                set(UserData.(EBname{1}),'ForegroundColor',[0.7 0 0]);
            end
        end
    end
    
    % Toggle switch for duration perturbation vs. delay 
    togglePanelXPos = 0.025;
    togglePanelXSpan = 0.125;
    togglePanelYSpan = 0.15;
    togglePanelYPos = 0.025;
    togglePanelPos = [togglePanelXPos togglePanelYPos togglePanelXSpan togglePanelYSpan]; 
    UserData.togglePanel = uipanel(UserData.f,'Units','Normalized','Position',...
                togglePanelPos,'Title',' signalOut info ',...
                'Tag','signalOut_info','TitlePosition','CenterTop',...
                'FontSize',0.02,'FontUnits','Normalized','Visible','on');
            
    UserData.pertToggle = uicontrol(UserData.togglePanel,'Style','togglebutton',...
        'String','Duration pert.',...
        'Value',1,...
        'BackgroundColor',UserData.colors.pert/0.9,...
        'Units','Normalized','Position',[0.1 0.6 0.8 0.3],...
        'FontUnits','Normalized','FontSize',0.6,...
        'Callback',@toggle_sigOut);
    UserData.lagToggle = uicontrol(UserData.togglePanel,'Style','togglebutton',...
        'String','Delay magnitude',...
        'Value',0,...
        'BackgroundColor',UserData.colors.unselected,...
        'Units','Normalized','Position',[0.1 0.2 0.8 0.3],...
        'FontUnits','Normalized','FontSize',0.6,...
        'Callback',@toggle_sigOut);
            

    % create sort selection buttons
    groupPanelXPos = 0.175;
    groupPanelXSpan = 0.15;
    groupPanelYSpan = 0.11;
    groupPanelYPos = UserData.xPosMax - groupPanelYSpan;

    groupPanelPos = [groupPanelXPos groupPanelYPos groupPanelXSpan groupPanelYSpan]; 
    UserData.groupPanel = uipanel(UserData.f,'Units','Normalized','Position',...
                groupPanelPos,'Title',' group by: ',...
                'Tag','group_by','TitlePosition','CenterTop',...
                'FontSize',0.02,'FontUnits','Normalized','Visible','on');
    % I'm going to be more hard-coded about this --- might make this better later. RK June 2025
    groupTypes = {'word' 'cond' 'bPerturbed'}; 
        
    groupButtonYSep = 0.05;
    groupButtonXSep = 0.05;
    groupButtonYSpan = 1 - 2*groupButtonYSep;
    groupButtonYPos = groupButtonYSep;
    groupButtonXSpan = 1 - 2*groupButtonXSep;
    groupButtonXPos = groupButtonXSep;
    groupButtonPos = [groupButtonXPos groupButtonYPos groupButtonXSpan groupButtonYSpan];
    if ismac
        groupFontSize = 0.2;
    else
        groupFontSize = 0.3;
    end
    UserData.groupSel = uicontrol(UserData.groupPanel,'style','popup',...
        'string',groupTypes,...
        'Units','Normalized','Position',groupButtonPos,...
        'FontUnits','Normalized','FontSize',groupFontSize,...
        'Callback',@update_plots);


    % create trial selection buttons
    trialPanelXPos = 0.35;
    trialPanelXSpan = 0.2;
    trialPanelYSpan = 0.11;
    trialPanelYPos = UserData.xPosMax-trialPanelYSpan;
    trialPanelPos = [trialPanelXPos trialPanelYPos trialPanelXSpan trialPanelYSpan]; 
    UserData.trialPanel = uibuttongroup(UserData.f,'Units','Normalized','Position',...
                trialPanelPos,'Title',' trial selection ',...
                'Tag','trial_sel','TitlePosition','CenterTop',...
                'FontSize',0.02,'FontUnits','Normalized','Visible','on');

    trialTypes = {'all_trials', 'select_trial'};
    nTrialTypes = length(trialTypes);

    trialButtonYSep = 0.05;
    trialButtonXSep = 0.05;
    trialButtonYSpan = 1 - 2*trialButtonYSep;
    trialButtonYPos = trialButtonYSep;
    trialButtonXSpan = (1 - trialButtonYSep*(nTrialTypes+1))/nTrialTypes;
    for iButton = 1: nTrialTypes
        TBname = strcat('TB_', trialTypes(iButton));
        trialButtonXPos = trialButtonXSep*iButton + trialButtonXSpan*(iButton-1);
        trialButtonPos = [trialButtonXPos trialButtonYPos trialButtonXSpan trialButtonYSpan];
        UserData.(TBname{1}) = uicontrol(UserData.trialPanel,...
            'Style','togglebutton','String',trialTypes(iButton),...
            'Units','Normalized','Position',trialButtonPos,...
            'FontUnits','Normalized','FontSize',0.3);
    end
    set(UserData.TB_all_trials,'Callback',@TB_all)
    set(UserData.TB_select_trial,'Callback',@TB_sel)
    
end

function errors = get_dataVals_errors(UserData,dataVals, segFields)
% Function that calculates different possible errors. Note that there are fewer than in formants---basically looking for
% things that are suspiciously long or short. Early/late still needs to be fixed
    outstring = textwrap(UserData.warnText,{'Checking for errors'});
    set(UserData.warnPanel,'HighlightColor','yellow')
    set(UserData.warnText,'String',outstring)

    badTrials = [];
    shortTrials = [];
    longTrials = [];
    flipTrials = []; 
    fishyTrials = []; 
    earlyTrials = [];
    lateTrials = [];
    goodTrials = [];

    %% put trials into error categories
    for i = 1:length(dataVals)
        if dataVals(i).bExcl
            badTrials = [badTrials dataVals(i).trial]; %#ok<*AGROW>
        elseif dataVals(i).(segFields.dur) < UserData.errorParams.shortThresh %check for too short trials
            shortTrials = [shortTrials dataVals(i).trial];
        elseif dataVals(i).bFlip % check for segmentation that is backwards
            flipTrials = [flipTrials dataVals(i).trial];
        elseif dataVals(i).bFishy % check for trials where something is off
            fishyTrials = [fishyTrials dataVals(i).trial]; 
        elseif dataVals(i).(segFields.dur) > UserData.errorParams.longThresh %check for too long trials
            longTrials = [longTrials dataVals(i).trial];
            % RK to do 
        elseif (isfield(UserData.expt, 'timing') && isfield(UserData.expt.timing, 'stimdur') && (dataVals(i).(segFields.lag) + dataVals(i).(segFields.dur)) > UserData.errorParams.lateThresh_ratio*UserData.expt.timing.stimdur) || ...
                ~(isfield(UserData.expt, 'timing') && isfield(UserData.expt.timing, 'stimdur')) && (dataVals(i).(segFields.lag) + dataVals(i).(segFields.dur)) > UserData.errorParams.lateThresh_absolute
            % check segment endpoint relative to stimdur if possible.
            % Otherwise, use arbitrary duration, to wit UserData.errorParams.lateThresh
            lateTrials = [lateTrials dataVals(i).trial];
        elseif dataVals(i).(segFields.lag) < UserData.errorParams.earlyThresh_absolute 
            % check segment endpoint relative to stimdur if possible.
            % Otherwise, use arbitrary duration, to wit UserData.errorParams.lateThresh
            earlyTrials = [earlyTrials dataVals(i).trial];
        else
            goodTrials = [goodTrials dataVals(i).trial];
        end
    end

    errors.badTrials = badTrials;
    errors.shortTrials = shortTrials;
    errors.flipTrials = flipTrials; 
    errors.fishyTrials = fishyTrials; 
    errors.longTrials = longTrials;
    errors.earlyTrials = earlyTrials;
    errors.lateTrials = lateTrials;
    errors.goodTrials = goodTrials;
    
    set(UserData.warnText,'String',[])
    set(UserData.warnPanel,'HighlightColor',[1 1 1])
end

function update_plots(src,evt)
% this is the function that replots everything if you switch error type or regenerate datavals, etc. 
    UserData = guidata(src);
    errorField = UserData.errorPanel.SelectedObject.String{1};
    UserData.trialset = UserData.errors.(errorField);
    grouping = UserData.groupSel.String{UserData.groupSel.Value};
    if isfield(UserData,'htracks')
        delete(UserData.hsub);
        UserData = rmfield(UserData,'htracks');
        UserData = rmfield(UserData,'hsub');
    end
    if isfield(UserData,'noPlotMessage')
        delete(UserData.noPlotMessage);
        UserData = rmfield(UserData,'noPlotMessage');
    end
    if isempty(UserData.trialset) || strcmp(errorField,'badTrials')
        UserData.noPlotMessage = uicontrol(UserData.plotPanel,'style','text',...
            'String','No data to plot',...
            'Units','Normalized','Position',[.1 .4 .8 .2],...
            'FontUnits','Normalized','FontSize',0.3);
    else
        outstring = textwrap(UserData.warnText,{'Plotting data'});
        set(UserData.warnPanel,'HighlightColor','yellow')
        set(UserData.warnText,'String',outstring)
        pause(0.0001)
        if UserData.pertToggle.Value
            sigOut_segField = 'dur'; 
        else
            sigOut_segField = 'lag'; 
        end
        [UserData.htracks,UserData.hsub] = plot_rawDurs(UserData.dataValsIn,UserData.dataValsOut,UserData.segFields.(sigOut_segField),grouping,UserData.trialset,UserData.plotPanel,UserData.expt);
        set(UserData.warnText,'String',[])
        set(UserData.warnPanel,'HighlightColor',[1 1 1])
        for iPlot = 1:length(UserData.htracks)
            for iLine = 1:length(UserData.htracks(iPlot).dur)
                set(UserData.htracks(iPlot).dur(iLine),'ButtonDownFcn',{@pick_line,iLine,iPlot})
                set(UserData.htracks(iPlot).pert(iLine),'ButtonDownFcn',{@pick_line,iLine,iPlot})
            end
        end
    end
    outstring = textwrap(UserData.warnText,{strcat(num2str(length(UserData.trialset)),' trials selected')});
    set(UserData.warnText,'String',outstring)
    guidata(src,UserData);
end

function pick_line(src,evt,iLine,iPlot)
% This is a function that highlights a trial that you want to look at more carefully 
    UserData = guidata(src);
    if UserData.pertToggle.Value 
        pertColor = UserData.colors.pert;
    else
        pertColor = UserData.colors.lag;
    end
    UserData.TB_select_trial.Value = 1;
    
    outstring = textwrap(UserData.warnText,{'Selected trial: ', src.Tag});
    set(UserData.warnText,'String',outstring)
    UserData.trialset = str2double(src.Tag);
    
    selF = UserData.htracks(iPlot).dur(iLine);
    selP = UserData.htracks(iPlot).pert(iLine); 
    set(UserData.htracks(iPlot).dur(iLine),'MarkerFaceColor',UserData.colors.dur,'MarkerSize',8)
    set(UserData.htracks(iPlot).pert(iLine),'MarkerFaceColor',pertColor,'MarkerSize',8);
%     uistack(UserData.htracks(iPlot).dur(iLine),'top'); % RK note: this doesn't work with yyaxis, and plotyy is going to
%     deprecate so I don't feel like changing this. 
    
    notSel = 1:length(UserData.htracks(iPlot).dur); 
    notSel(iLine) = []; 
    
    % Set all the other plots also to unselected
    for i = 1:length(UserData.htracks)
        if i ~= iPlot
            set(UserData.htracks(i).dur(:),'MarkerFaceColor',UserData.colors.unselected,'MarkerSize',5)
            set(UserData.htracks(i).pert(:),'MarkerFaceColor',UserData.colors.unselected,'MarkerSize',5)
        else
            set(UserData.htracks(i).dur(notSel),'MarkerFaceColor',UserData.colors.unselected,'MarkerSize',5)
            set(UserData.htracks(i).pert(notSel),'MarkerFaceColor',UserData.colors.unselected,'MarkerSize',5)
        end
    end
    guidata(src,UserData);
end

function launch_GUI(src,evt)
% To launch audioGUI. Gives you the option to do signalIn only, out, or both sequentially 
    UserData = guidata(src);
    bIn = 0; 
    bOut = 0; 
    answer = questdlg('Would you like to check signalIn, signalOut, or both?', ...
            'Which buffer', ... % question dialog title
            'signalIn only','signalOut only','both',... % button names
            'signalIn only'); % Default selection 
        
    if strcmp(answer, 'signalIn only') || strcmp(answer, 'both')
        bIn = 1; 
    end
    if strcmp(answer, 'signalOut only') || strcmp(answer, 'both')
        bOut = 1; 
    end

    if bIn
        audioGUI(UserData.dataPath,UserData.trialset,'signalIn',[],0)
    end
    if bOut
        audioGUI(UserData.dataPath,UserData.trialset,'signalOut',[],0)
    end
end

function reload_dataVals(src,evt)
% To trigger recalculating dataVals (after, say, correcting a trial) 
    UserData = guidata(src);
    delete(UserData.errorPanel)
    delete(UserData.groupPanel)
    delete(UserData.trialPanel)
    if isfield(UserData,'htracks')
        delete(UserData.hsub);
        UserData = rmfield(UserData,'htracks');
        UserData = rmfield(UserData,'hsub');
    end
    bIn = 0; 
    bOut = 0; 
    answer = questdlg('Would you like to regenerate signalIn, signalOut, or both?', ...
            'Which buffer', ... % question dialog title
            'signalIn only','signalOut only','both',... % button names
            'signalIn only'); % Default selection 
        
    if strcmp(answer, 'signalIn only') || strcmp(answer, 'both')
        bIn = 1; 
    end
    if strcmp(answer, 'signalOut only') || strcmp(answer, 'both')
        bOut = 1; 
    end
    [UserData.dataValsIn,UserData.dataValsOut,UserData.expt] = load_dataVals(UserData,UserData.dataPath,1,bIn,bOut,UserData.dataValsFunction);
    UserData.errors = get_dataVals_errors(UserData,UserData.dataValsIn,UserData.segFields);
    UserData = generate_menus(UserData);
    guidata(src,UserData);
end

function [dataValsIn, dataValsOut, expt] = load_dataVals(UserData,dataPath,bCalc,bIn,bOut,dataValsFunction)
% Function that loads dataVals. 
% if bCalc, you are regenerating 
    if bCalc
        msg = 'Regenerating and loading dataVals';
    else
        msg = 'Loading dataVals';
    end
    outstring = textwrap(UserData.warnText,{msg});
    set(UserData.warnPanel,'HighlightColor','yellow')
    set(UserData.warnText,'String',outstring)
    varargin = UserData.varargin; 
    
    % Because dur uses both in and out, but sometimes you only needed to fix one or the other's segmentation 
    if bIn 
        dataValsFunction([], 'signalIn', [], varargin{1:end});  
        load(fullfile(dataPath,'dataVals_signalIn.mat'))
        dataValsIn = dataVals; 
        clear dataVals; 
    else
        dataValsIn = UserData.dataValsIn; 
    end
    if bOut
        dataValsFunction([], 'signalOut', [], varargin{1:end});  
        load(fullfile(dataPath,'dataVals_signalOut.mat'))
        dataValsOut = dataVals; 
        clear dataVals; 
    else
        dataValsOut = UserData.dataValsOut; 
    end
    load(fullfile(dataPath,'expt.mat'), 'expt')
    set(UserData.warnText,'String',[])
    set(UserData.warnPanel,'HighlightColor',[1 1 1])
end

function TB_all(src,evt)
% Function that selects all trials (changes color; launch_GUI will now do all in a section)
    UserData = guidata(src);

    if UserData.pertToggle.Value
        pertColor = UserData.colors.pert;
    else
        pertColor = UserData.colors.lag;
    end
    for i = 1:length(UserData.htracks)
        set(UserData.htracks(i).dur(:),'MarkerFaceColor',UserData.colors.dur,'MarkerSize',5)
        set(UserData.htracks(i).pert(:),'MarkerFaceColor',pertColor,'MarkerSize',5)
    end
    errorField = UserData.errorPanel.SelectedObject.String{1};
    UserData.trialset = UserData.errors.(errorField);
    outstring = textwrap(UserData.warnText,{strcat(num2str(length(UserData.trialset)),' trials selected')});
    set(UserData.warnText,'String',outstring)
    guidata(src,UserData);
end

function TB_sel(src,evt)
    UserData = guidata(src);
    outstring = textwrap(UserData.warnText,{'Select a trial'});
    set(UserData.warnText,'String',outstring)
    
    guidata(src,UserData);
end

function toggle_sigOut(src,evt)
    UserData = guidata(src); 
    pause(0.05); 
    % Check if you just clicked on "Duration perturbation" 
    bDur = strcmp(evt.Source.String, 'Duration pert.'); 
    
    % Change the other button too 
    if bDur
        % If the action was to untoggle  pert, 
        if UserData.pertToggle.Value == 0
            UserData.pertToggle.BackgroundColor = UserData.colors.unselected; 
            UserData.lagToggle.Value = 1; 
            UserData.lagToggle.BackgroundColor = UserData.colors.lag/0.9; 
        else            
            UserData.pertToggle.BackgroundColor = UserData.colors.pert/0.9; 
            UserData.lagToggle.Value = 0; 
            UserData.lagToggle.BackgroundColor = UserData.colors.unselected; 
        end
    else
        % If the action was to untoggle lag, 
        if UserData.lagToggle.Value == 0
            UserData.pertToggle.Value = 1; 
            UserData.pertToggle.BackgroundColor = UserData.colors.pert/0.9; 
            UserData.lagToggle.BackgroundColor = UserData.colors.unselected; 
        else
            UserData.pertToggle.Value = 0; 
            UserData.pertToggle.BackgroundColor = UserData.colors.unselected; 
            UserData.lagToggle.BackgroundColor = UserData.colors.lag/0.9; 
        end
    end
    
    % Then replot 
    update_plots(src, evt); 

end