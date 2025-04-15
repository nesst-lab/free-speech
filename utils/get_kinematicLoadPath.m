function [dataPath] = get_kinematicLoadPath(exptName,sid,varargin)
%GET_KINEMATICLOADPATH  Get kinematic load path for given experiment/subject.

if nargin < 2 || isempty(sid) % need 'isempty' here because '[]' is numeric
    sid = [];
elseif isnumeric(sid)
    if strcmp(exptName, 'cerebTimeAdapt', 'taimComp', 'timitate')
        sid = sprintf('sp%03d',sid);
    else
        % Adjustment for NeSST Lab codes
        sid = sprintf('nh%04d',sid); 
    end
elseif ~ischar(sid)
    error('Subject ID must be a number or character string.')
end

dataPath = get_kExptLoadPath(exptName,'kinematicdata',sid,varargin{:});
