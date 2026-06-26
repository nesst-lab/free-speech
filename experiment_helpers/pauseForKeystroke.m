function [pauseDur] = pauseForKeystroke(key, h)

starttime = GetSecs; 
bTerminate = 0; 
while ~bTerminate
    k = waitforbuttonpress; 
    for i = 1:length(h)
        keydown{i} = get(h(i), 'CurrentCharacter'); 
    end
    
    if any(ismember(keydown, key))
        bTerminate = 1; 
    else
        bTerminate = 0; 
        clear keydown; 
    end
end
endtime = GetSecs; 
pauseDur = endtime - starttime; 


