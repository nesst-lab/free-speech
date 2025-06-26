function [arpastring] = word2arpabet(word, dictionary)

dbstop if error

if nargin < 2 || isempty(dictionary), dictionary = 'english_us_arpaOnly'; end

%% 
dictFile = readtable(fullfile('C:\Users\Public\Documents\software\MFA', [dictionary '.csv']), ...
    'ReadVariableNames', 0); 
for i = 1:width(dictFile)-1
    segHeaders{i} = sprintf('seg%d', i); 
end
dictFile.Properties.VariableNames = ['Word', segHeaders]; 

%%

wordix = find(strcmpi([dictFile.Word], word));  

versionsLeft = length(wordix); % some words have multiple pronunciations
if ~versionsLeft
    warning('This word is not in the dictionary!'); 
    arpastring = {}; 
    return; 
end
while versionsLeft
    arpastring{versionsLeft} = {}; 
    e = 1; 
    for s = 1:length(segHeaders)
        segHeader = segHeaders{s}; 
        seg = dictFile.(segHeader){wordix(versionsLeft)}; 
        if ~isempty(seg)
            arpastring{versionsLeft}{e} = seg; 
            e = e+1; 
        end
    end

    versionsLeft = versionsLeft - 1; 
end










end