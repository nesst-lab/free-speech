function [exptPath] = get_kExptLoadPath(exptName,varargin)

if nargin < 1, exptName = []; end

if ispc
    % Normal lab computers
    basePath = '\\umad.umsystem.edu\RDE\rktfn-lab\experiments\'; 

elseif isunix
    basePath = '\\E:\rktfn-lab\experiments\'; %% placeholder 
else
    basePath = '\\umad.umsystem.edu\RDE\rktfn-lab\experiments\'; %% placeholder
end

exptPath = fullfile(basePath,exptName,varargin{:});
