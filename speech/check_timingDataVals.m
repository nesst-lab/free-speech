function [] = check_timingDataVals(dataPath, seg_list, errorParams, dataValsFunction)
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
%       seg_list                the NAME of the segment that you are checking. This is whatever the fieldname "prefix" is in
%                               dataVals. e.g. if you have 'e_dur' 'e_startTime' then you should put in 'e'. This is not
%                               necessarily the same as what it is called in MFA/user events! 
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

%% Load in various data structures

if exist(fullfile(dataPath, 'dataVals_signalIn.mat'), 'file')
    load(fullfile(dataPath, 'dataVals_signalIn.mat')); 
    dataValsIn = dataVals; 
    clear dataVals; 
else
    dataValsIn = dataValsFunction([], [], 'signalIn'); 
end

if exist(fullfile(dataPath, 'dataVals_signalOut.mat'), 'file')
    load(fullfile(dataPath, 'dataVals_signalOut.mat')); 
    dataValsOut = dataVals; 
    clear dataVals; 
else
    dataValsOut = dataValsFunction([], [], 'signalOut'); 
end

load(fullfile(dataPath, 'expt.mat')); 


%% Set up the fieldnames you'll be looking for in dataVals

segFields.dur = [seg_list 'Dur']; 
segFields.start = [seg_list 'Start_time']; 


%% Set up error parameters

% config errorParams
defaultParams.shortThresh = 0.05; % less than 50 ms 
defaultParams.flipThresh = 0; % if you have a negative duration, you probably flipped around user events 
defaultParams.longThresh = 1; %longer than 1 second
defaultParams.jumpThresh = 200; %in Hz, upper limit for sample-to-sample change to detect jumpTrials in F1 trajectory
defaultParams.fishyFThresh = [200 1100]; %acceptable range of possible F1 values
    % ratio used to determine "late" or not. Absolute duration only used 
defaultParams.lateThresh_ratio = 0.96; % acceptable endpoint ratio for speech before trial ends "too late"
defaultParams.lateThresh_absolute = 1.5; % acceptable endpoint in seconds for speech before trial ends "too late". Only used as fallback if trial duration not available.
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

pause; 


%%


        

        
        
      

























































%%
 























end

function save_exit(hObject,eventdata)
    delete(h_tdv); 
%         answer = questdlg('Save current OST parameters and exit?', ...
%             'Exit GUI', ... % question dialog title
%             'Cancel (do not exit)','Save and exit','Exit without saving',... % button names
%             'Cancel (do not exit)'); % Default selection 
%         switch answer
%             case 'Save and exit'
%                 expt = x; 
%                 
%                 % Check if you did any recalculation, if you did but not for all trials, ask if you want to do them all
%                 bNeedToSaveData = 0; 
%                 if ~bAllOstRecalculated
%                     recalculateAnswer = questdlg('You have recalculated a subset of the trials in this data structure. Would you like to apply the current parameters to all trials?', ...
%                         'Recalculate all OSTs', ... % question dialog title
%                         'Yes, recalculate all', 'No, keep this subset', 'Cancel (do not exit)', ... % button names
%                         'Yes, recalculate all'); % Default selection 
% 
%                     
%                     switch recalculateAnswer
%                         case 'Yes, recalculate all'
%                             fWaiting = waitbar(0,'Setting OST parameters...');
%                             waitbar(0.33,fWaiting,'Calculating new OST vectors...')
%                             ost_calc = calc_newAudapterData({y.signalIn},p.audapter_params,trackingFileDir,trackingFileName,'ost_stat');
%                             
%                             % Also put in new OST values for all the trials 
%                             waitbar(0.66,fWaiting,'Writing trial OST information to data...')
%                             set_ost(trackingFileDir,trackingFileName,ostStatus,hdropdown.heuristicChoice.String{hdropdown.heuristicChoice.Value},...
%                                 str2double(hedit.statusParam1.String),str2double(hedit.statusParam2.String),str2double(hedit.statusParam3.String)); 
% %                             for o = 1:length(ostList)
% %                                 ostNumber = str2double(ostList{o});
% %                                 [heur,param1,param2] = get_ost(trackingFileDir,trackingFileName,ostNumber,'working'); 
% %                                 calcSubjOstParams{o} = {ostNumber heur param1 param2}; 
% %                             end
%                             calcSubjOstParams = get_ost(trackingFileDir, trackingFileName, 'full', 'working'); 
%                             for i = 1:length(y)
%                                 y(i).calcSubjOstParams = calcSubjOstParams; 
%                             end
%                             
%                             waitbar(1,fWaiting,'Done')
%                             pause(0.5)
%                             close(fWaiting)
%                             bNeedToSaveData = 1; 
%                         case 'No, keep this subset'
%                             fprintf('Some trials may be calculated with different OST parameters than others.\n')                            
%                     end                        
%                     
%                 end
%                 
% 
%                 startWaitBar = 0; 
%                 fWaiting = waitbar(0,'Saving...'); 
%                 if any(~cellfun(@isempty,ost_calc)) % if you did any calculation of new OSTs at all. if not it will not be saved (to save time)
%                     startWaitBar = startWaitBar + 0.25; 
%                     waitbar(startWaitBar,fWaiting,'Adding new OSTs to data structure...'); 
%                     for i = 1:length(y)
%                         y(i).ost_calc = ost_calc{i}; 
%                     end
%                     bNeedToSaveData = 1;                     
%                 end
%                 
%                 if any(~cellfun(@isempty,signalOut_calc)) % if you did any calculation of new signal outs at all. if not it will not be saved (to save time)
%                     startWaitBar = startWaitBar + 0.25; 
%                     waitbar(startWaitBar,fWaiting,'Adding new signalOuts to data structure...'); 
%                     for i = 1:length(y)
%                         y(i).signalOut_calc = signalOut_calc{i}; 
%                     end
%                     bNeedToSaveData = 1;                     
%                 end
%                 
%                 if any(~cellfun(@isempty,calcPcfLine)) % if you did any calculation of new signal outs at all. if not it will not be saved (to save time)
%                     startWaitBar = startWaitBar + 0.25; 
%                     waitbar(startWaitBar,fWaiting,'Adding new pcfLines to data structure...'); 
%                     for i = 1:length(y)
%                         y(i).calcPcfLine = calcPcfLine{i}; 
%                     end
%                     bNeedToSaveData = 1;                     
%                 end
%                 
%                 if bNeedToSaveData
%                     data = y; 
%                     switch x.name
%                         case 'dipSwitch' % dipswitch has exceptional behavior because it can be run on a mac
%                             isOnServer = exist(get_acoustLoadPath(x.name,x.snum,x.session,word),'dir');
%                             if isOnServer
%                                 savePath = get_acoustLoadPath(x.name,x.snum,sprintf('session%d', x.session),word);
%                             else
%                                 if ispc && strcmp(expt.dataPath(1), '/') % on pc, but dataPath is Mac formatted
%                                     savePath = pwd;
%                                     warning('OS mismatch -- couldn''t save to expt.dataPath. Saving instead to current directory: \n%s\n', pwd);
%                                 else
%                                     savePath = fullfile(x.dataPath,sprintf('session%d', x.session),word);
%                                 end
%                             end
%                         case 'timeAdapt' % timeAdapt has exceptional behavior because the expt.dataPath was saved for whole experiment, not word-specific 
%                             isOnServer = exist(get_acoustLoadPath(x.name,x.snum,word),'dir');
%                             if isOnServer
%                                 savePath = get_acoustLoadPath(x.name,x.snum,word);                                
%                             else
%                                 savePath = get_acoustSavePath(x.name,x.snum,word); 
%                             end
%                             
%                             if strcmp(x.conds,'pre')
%                                 savePath = fullfile(savePath,'pre'); 
%                             end
%                             
%                         otherwise % Assume that you will simply save to dataPath, but check if it should go to server or not
%                             % Translate between server path and expt path to get two options
%                             dataPathParts = strsplit(x.dataPath, 'experiments'); 
%                             if length(dataPathParts) > 1 % assumes you're using default SMNG filepath structures and might access SMNG server
%                                 serverPrefix = '\\wcs-cifs.waisman.wisc.edu\wc\smng\'; 
%                                 serverPath = fullfile(serverPrefix, 'experiments', dataPathParts{2}); 
%                                 isOnServer = exist(serverPath,'dir'); 
%                                 savePath = choosePathDialog({serverPath, x.dataPath, pwd}, isOnServer); 
%                             else % not using default SMNG filepath structure; don't offer SMNG server
%                                 savePath = choosePathDialog({x.dataPath, pwd}, 0);
%                             end
%                             
%                             % If you've hit cancel when choosing, then take away dialogs and don't save or anything
%                             if ~savePath
%                                 waitbar(1,fWaiting,'Canceling save')
%                                 pause(0.5)
%                                 delete(fWaiting)
%                                 return; 
%                             end
%                             
%                             if ~exist(savePath, 'dir')
%                                 shouldIMkDir = questdlg(sprintf('The path you chose does not currently exist. Would you like to create this directory and save?\n\n Chosen path: %s', savePath), ...
%                                     'Verify creating directory', ... % question dialog title
%                                     'Yes, create this directory', 'No, cancel save', ... % button names
%                                     'No, cancel save'); % Default selection 
%                                 
%                                 if strcmp(shouldIMkDir, 'Yes, create this directory')
%                                     mkdir(savePath); 
%                                 else
%                                     return; 
%                                 end
%                             end
% 
%                     end
%                     waitbar(0.9,fWaiting,'Saving data...')
%                     save(fullfile(savePath,'data.mat'),'data')
%                     waitbar(0.95,fWaiting,'Saving expt...')
%                     save(fullfile(savePath,'expt.mat'),'expt'); 
%             
%                 end    
%                 waitbar(1,fWaiting,'Done')
%                 pause(0.5)
%                 delete(fWaiting)
%                 try delete(alert2mismatchMex); catch; end
%                 try delete(fWaiting); catch; end
%                 delete(hf)
%             case 'Exit without saving'
%                 try delete(alert2mismatchMex); catch; end
%                 try delete(fWaiting); catch; end
%                 delete(hf)            
%         end
end


function delete_func(src,event)
    viewer_end_state = 1; 
end

function UserData = generate_menus(UserData)
    % create error type buttons
    errorPanelXPos = 0.025;
    errorPanelXSpan = 0.125;
    errorPanelYSpan = 0.95;
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
    outstring = textwrap(UserData.warnText,{'Checking for errors'});
    set(UserData.warnPanel,'HighlightColor','yellow')
    set(UserData.warnText,'String',outstring)

    badTrials = [];
    shortTrials = [];
    longTrials = [];
    flipTrials = []; 
    earlyTrials = [];
    lateTrials = [];
    goodTrials = [];

    %% put trials into error categories
    for i = 1:length(dataVals)
        if dataVals(i).bExcl
            badTrials = [badTrials dataVals(i).token]; %#ok<*AGROW>
        elseif dataVals(i).(segFields.dur) < UserData.errorParams.shortThresh && dataVals(i).(segFields.dur) > UserData.errorParams.flipThresh %check for too short trials
            shortTrials = [shortTrials dataVals(i).token];
        elseif dataVals(i).(segFields.dur) < UserData.errorParams.flipThresh % check for segmentation that is backwards
            flipTrials = [flipTrials dataVals(i).token];
        elseif dataVals(i).dur > UserData.errorParams.longThresh %check for too long trials
            longTrials = [longTrials dataVals(i).token];
%         elseif (isfield(UserData.expt, 'timing') && isfield(UserData.expt.timing, 'stimdur') && dataVals(i).ampl_taxis(end) > UserData.errorParams.lateThresh_ratio*UserData.expt.timing.stimdur) || ...
%                 ~(isfield(UserData.expt, 'timing') && isfield(UserData.expt.timing, 'stimdur')) && dataVals(i).ampl_taxis(end) > UserData.errorParams.lateThresh_absolute
%             % check vowel endpoint relative to stimdur if possible.
%             % Otherwise, use arbitrary duration, to wit UserData.errorParams.lateThresh
%             lateTrials = [lateTrials dataVals(i).token];
        else
            goodTrials = [goodTrials dataVals(i).token];
        end
    end

    errors.badTrials = badTrials;
    errors.shortTrials = shortTrials;
    errors.flipTrials = flipTrials; 
    errors.longTrials = longTrials;
    errors.earlyTrials = earlyTrials;
    errors.lateTrials = lateTrials;
    errors.goodTrials = goodTrials;
    
    set(UserData.warnText,'String',[])
    set(UserData.warnPanel,'HighlightColor',[1 1 1])
end

function update_plots(src,evt)
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
        [UserData.htracks,UserData.hsub] = plot_rawDurs(UserData.dataValsIn,UserData.segFields.dur,grouping,UserData.trialset,UserData.plotPanel,UserData.expt);
        set(UserData.warnText,'String',[])
        set(UserData.warnPanel,'HighlightColor',[1 1 1])
        for iPlot = 1:length(UserData.htracks)
            for iLine = 1:length(UserData.htracks(iPlot).dur)
                set(UserData.htracks(iPlot).dur(iLine),'ButtonDownFcn',{@pick_line,iLine,iPlot})
            end
        end
    end
    outstring = textwrap(UserData.warnText,{strcat(num2str(length(UserData.trialset)),' trials selected')});
    set(UserData.warnText,'String',outstring)
    guidata(src,UserData);
end

function pick_line(src,evt,iLine,iPlot)
    UserData = guidata(src);
    unselectedColor = [0.7 0.7 0.7];
    f1color = [0 0 1]; % blue
    f2color = [1 0 0]; % red
    UserData.TB_select_trial.Value = 1;
    
    outstring = textwrap(UserData.warnText,{'Selected trial: ', src.Tag});
    set(UserData.warnText,'String',outstring)
    UserData.trialset = str2double(src.Tag);
    
    selF = UserData.htracks(iPlot).dur;
    set(UserData.htracks(iPlot).dur(selF==src),'Color',f1color,'LineWidth',3)
    uistack(UserData.htracks(iPlot).dur(selF==src),'top');
    
    set(UserData.htracks(iPlot).dur(selF~=src),'Color',unselectedColor,'LineWidth',1)
    for i = 1:length(UserData.htracks)
        if i ~= iPlot
            set(UserData.htracks(i).dur(:),'Color',unselectedColor,'LineWidth',1)
        end
    end
    guidata(src,UserData);
end

function launch_GUI(src,evt)
    UserData = guidata(src);
    audioGUI(UserData.dataPath,UserData.trialset,UserData.buffertype,[],0, UserData.folderSuffix)
end