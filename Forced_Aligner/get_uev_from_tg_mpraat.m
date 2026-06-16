function [user_event_times, user_event_names] = get_uev_from_tg_mpraat(TextGrid, bRenameDuplicates)

% uses mpraat and DetectTextGridEncoding to generate event times and labels
% 
% NeSST Lab addition for kinematic tracking: bRenameDuplicates. This will rename events that share name with other events,
% e.g. 'bedhead' would have 'B' 'EH' 'D' 'H' 'EH' 'D'. The EH and D events will be renamed: EH1, EH2, D1, D2. 
% Defaults to 0 (backwards compatible) - RK June 2026

if nargin < 2 || isempty(bRenameDuplicates), bRenameDuplicates = 0; end

[tier,~] = tgRead(TextGrid, 'auto');

ntiers = length(tier.tier);

for i = 1:ntiers
    if strcmp((tier.tier{1,i}.name),'phones')
        phonetier = tier.tier{1,i};
        user_event_times = phonetier.T1;
        labels = phonetier.Label;
        user_event_names = cell(1,length(labels));
        %labels(regexp(labels,'[0,1,2]'))=[]; % remove any stress info % strip stress
        for l = 1:length(labels)
            lab = labels{l};
            lab(regexp(lab,'[0,1,2]'))=[];
            user_event_names{l} = char(lab);
        end
    end
end

% NeSST Lab addition 
if bRenameDuplicates
    renamed_uev_names = user_event_names; % initiate 
    definedUevNames = user_event_names(~cellfun(@isempty, user_event_names)); % this gets rid of the blank events at the beginning/end
    uniqueUevNames = unique(definedUevNames); % this gets the unique items   

    if length(uniqueUevNames) ~= length(user_event_names)
        % If there are strings that appear more than once
        % Loop through all the unique UEV names
        for i = 1:length(uniqueUevNames)
            uniqueUev = uniqueUevNames{i}; 
            dupUevIx = sort(find(strcmp(user_event_names, uniqueUev))); % check if there are multiple of them 

            % If there are duplicates of that name
            if length(dupUevIx) > 1 
                % Loop over those indices
                for d = 1:length(dupUevIx)
                    dIx = dupUevIx(d); 
                    renamed_uev_names{dIx} = sprintf('%s%d', user_event_names{dIx}, d); % Change them to, e.g., B1 B2 B3
                end
            end
        end
    end

    user_event_names = renamed_uev_names; 
end
