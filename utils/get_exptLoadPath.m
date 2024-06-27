function [exptPath] = get_exptLoadPath(exptName,varargin)

if nargin < 1, exptName = []; end

nesstComputers = {'WHITTAKER', 'PERTWEE', 'TENNANT', 'DAVISON', 'BAKER', 'MCCOY', 'MCGANN', 'CHLPR-CSJZ3M3'}; 
bjorndahlComputers = {'P-CBJORN-L'}; 

if ispc
    % Adjustment for using at NeSST Lab
    computerName = getenv('COMPUTERNAME');
    if contains(computerName, 'LEWIS221') || ismember(computerName, nesstComputers)
        username = getenv('USERNAME'); 
        if strcmp(computerName, 'WHITTAKER')
            % Dumb workaround for Whittaker
            basePath = ['D:\Users\' username '\OneDrive - University of Missouri\nesstlab\experiments\']; 
        elseif strcmp(computerName, 'PERTWEE')  % This is a hack for working sometimes on server and sometimes on nesst
            if ~strcmp(exptName, 'timitate') && ~strcmp(exptName, 'participant_database')
                basePath = '\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\';
            else
                basePath = ['C:\Users\' username '\OneDrive - University of Missouri\nesstlab\experiments\']; 
            end
        else
            basePath = ['C:\Users\' username '\OneDrive - University of Missouri\nesstlab\experiments\']; 
        end
    elseif ismember(computerName, bjorndahlComputers)
        basePath = 'C:\Users\Public\Documents\experiments\'; 
    else
        basePath = '\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\';
    end    
    
elseif ismac
    basePath = '/Volumes/smng/experiments/';
    if ~isfolder(basePath)
        basePath = '/Volumes/wc/experiments/';
    end
elseif isunix
    basePath = '/mnt/smng/experiments/'; %% placeholder
else
    basePath = '\\wcs-cifs.waisman.wisc.edu\wc\smng\experiments\'; %% placeholder
end

exptPath = fullfile(basePath,exptName,varargin{:});
