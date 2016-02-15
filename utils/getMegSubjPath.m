function [subjPath] = getMegSubjPath(exptName,sid,varargin)
%GETMEGSUBJPATH  Get path to MEG data for given subject/experiment.

if nargin < 2 || isempty(sid) % need 'isempty' here because '[]' is numeric
    sid = [];
elseif isnumeric(sid)
    sid = sprintf('s%02d',sid);
elseif ~ischar(sid)
    error('Subject ID must be a number or character string.')
end

subjPath = fullfile(get_exptPath(exptName),'megdata',sid,varargin{:});