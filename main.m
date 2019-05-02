%% Requirements
clear all;                          % clear current workspace

%% PRESETS
addpath(genpath('libs\BiomotionToolbox\BiomotionToolbox'))



%%


Screen('Preference', 'SkipSyncTests', 1);


fullName{1} = fullfile(pwd,'libs','BiomotionToolbox','BiomotionToolbox',...
    'BiomotionToolboxDemos','actions','Playtennis.rex'); % exact file location
fullName{2} = fullfile(pwd,'libs','BiomotionToolbox','BiomotionToolbox',...
    'BiomotionToolboxDemos','actions','19_01.bvh'); % exact file location
 
win = SetScreen('OpenGL', 1, 'Window', 1);  % Open a screen.
SetProjection(win);                         % Set the type of projection .

try   
    bm1 = BioMotion(fullName{2},'Filetype','bvh'); % load the data, tell the function %that you have a bvh file even though the extension is txt.
    bm2 = Copy(bm1); % load the data, tell the function %that you have a bvh file even though the extension is txt.
    bmarray=[bm1 bm2];
  % bm.Loop = 1;                            % Set the parameter to Loop.

    % make the movies loop.
    SetAll(bmarray,'Loop',2); % option 1 of SetqAll
    
 
    
    %%Put the actions in different positions
    SetAllVect(bmarray,'Position3D',[-win.Width/4 0 0 ; win.Width/4 0 0]);
    
    bmarray(2).Scramble =1;
    for n=1:4
        
         bmarray(2).ScrambleOffsets=(rand(((size(bmarray(2).ScrambleOffsets))))-.5) * 150;
        startTime=GetSecs;

        for fr = 1:sum(bmarray.nFrames)                   % Run through frames 1 until the end.)
            if KbCheck                          % Check for button presses, exit if any.
                break;
            end
            moglDrawDots3D(win.Number,bmarray.GetFrame(fr),7); % draw the dots, note the call %to GetFrame.
            Screen('Flip',win.Number);          % Display the dots on the screen.
        end
    end
    
    endTime=GetSecs-startTime;
    
    clear screen;
catch ME
    clear screen;
    rethrow(ME);
end






