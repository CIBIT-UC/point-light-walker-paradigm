%% Requirements
clear all;                          % clear current workspace

%% PRESETS
addpath(genpath('libs\BiomotionToolbox\BiomotionToolbox'))

%%
 
combiname = fullfile(pwd,'libs','BiomotionToolbox','BiomotionToolbox',...
    'BiomotionToolboxDemos','actions','19_01.txt'); % exact file location
 
win = SetScreen('OpenGL', 1, 'Window', 1);  % Open a screen.
SetProjection(win);                         % Set the type of projection .

try   
    bm = BioMotion(combiname,'Filetype','bvh'); % load the data, tell the function %that you have a bvh file even though the extension is txt.
    bm.Loop = 1;                            % Set the parameter to Loop.

    startTime=GetSecs;
    
    for fr = 1:bm.nFrames                   % Run through frames 1 until the end.
        if KbCheck                          % Check for button presses, exit if any.
            break;
        end
        moglDrawDots3D(win.Number,bm.GetFrame(fr),2); % draw the dots, note the call %to GetFrame.
        Screen('Flip',win.Number);          % Display the dots on the screen.
    end
    
    endTime=GetSecs-startTime;
    
    clear screen;
catch ME
    clear screen;
    rethrow(ME);
end




