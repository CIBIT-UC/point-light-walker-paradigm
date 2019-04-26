%% Requirements
clear all;                          % clear current workspace

%% PRESETS
addpath(genpath('libs\BiomotionToolbox\BiomotionToolbox'))

%%
 
fullName{1} = fullfile(pwd,'libs','BiomotionToolbox','BiomotionToolbox',...
    'BiomotionToolboxDemos','actions','49_04.c3d'); % exact file location
fullName{2} = fullfile(pwd,'libs','BiomotionToolbox','BiomotionToolbox',...
    'BiomotionToolboxDemos','actions','02_01.c3d'); % exact file location
 
win = SetScreen('OpenGL', 1, 'Window', 1);  % Open a screen.
SetProjection(win);                         % Set the type of projection .

try   
    bm1 = BioMotion(fullName{1},'Filetype','c3d'); % load the data, tell the function %that you have a bvh file even though the extension is txt.
    bm2 = BioMotion(fullName{2},'Filetype','c3d'); % load the data, tell the function %that you have a bvh file even though the extension is txt.
    bmarray=[ bm2];
  % bm.Loop = 1;                            % Set the parameter to Loop.

    % make the movies loop.
    SetAll(bmarray,'Loop',1); % option 1 of SetqAll
    
    startTime=GetSecs;
    
    for fr = 1:sum(bmarray.nFrames)                   % Run through frames 1 until the end.)
        if KbCheck                          % Check for button presses, exit if any.
            break;
        end
        moglDrawDots3D(win.Number,bmarray.GetFrame(fr),2); % draw the dots, note the call %to GetFrame.
        Screen('Flip',win.Number);          % Display the dots on the screen.
    end
    
    endTime=GetSecs-startTime;
    
    clear screen;
catch ME
    clear screen;
    rethrow(ME);
end




