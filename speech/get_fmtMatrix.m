function [rawf1,rawf2] = get_fmtMatrix(dataVals,inds,bMels,bFilt)
%GET_FMTMATRIX  Generate matrix of formant tracks from a dataVals object.
%   GET_FMTMATRIX(DATAVALS,INDS,BMELS,BFILT) extracts only the trials INDS
%   from DATAVALS and concatenates their formant tracks into the matrices
%   RAWF1 and RAWF2. BMELS and BFILT are binary variables that determine
%   whether the formant tracks are converted to mels and filtered,
%   respectively.
%
% CN 5/2014
% TODO: return a single struct RAWTRACKS with fields f1, f2, f0...?

if nargin < 2 || isempty(inds), inds = 1:length(dataVals); end
if nargin < 3 || isempty(bMels), bMels = 1; end
if nargin < 4 || isempty(bFilt), bFilt = 1; end

rawf1 = []; rawf2 = []; missingTrials = [];
dvinds = [dataVals.token];
for trialind = inds  % for each trial in the condition
    dvind = find(dvinds==trialind);
    if ~isempty(dvind)
        dat1 = dataVals(dvind).f1; % assumes Hz
        dat1 = dat1(~isnan(dat1));
        dat2 = dataVals(dvind).f2;
        dat2 = dat2(~isnan(dat2));
        
        if bFilt % try filtering
            hb = hamming(8)/sum(hamming(8));
            try
                dat1 = filtfilt(hb, 1, dat1);
                dat2 = filtfilt(hb, 1, dat2);
            catch  %#ok<*CTCH>
            end
        end
        
        if bMels % convert to mels
            dat1 = hz2mels(dat1);
            dat2 = hz2mels(dat2);
        end
        
        % add data to matrix
        rawf1 = nancat(rawf1,dat1);
        rawf2 = nancat(rawf2,dat2);
    else
        missingTrials(end+1) = trialind; %#ok<AGROW>
    end
end

warning('Missing trials: %s',num2str(missingTrials));
if isempty(rawf1)
    warning('No trials in this condition found.');
end