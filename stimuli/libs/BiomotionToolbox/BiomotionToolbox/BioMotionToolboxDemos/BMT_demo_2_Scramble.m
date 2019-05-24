% BMT_demo_2_Scramble shows how to scramble stimuli.Inversion, and
% phase scambling works similarly.

clear all;                          % clear current workspace

combiname = './actions/Playtennis.rex';   % exact file location

win = SetScreen('OpenGL',1);        % Open a screen
SetProjection(win);                 % Set the type of projection

try
    bm1 = BioMotion(combiname,'Filetype','vanrie');% load first figure
    bm2 = Copy(bm1);% create second figure
    
    bmarray = [bm1 bm2];
    SetAll(bmarray,'Loop',1);   % Set the parameter to Loop
    
    %%Or you can do:
    % bm1.Loop = 1;             % Set the parameter to Loop
    % bm2.Loop = 1;
    %%Or alternatively
    % bmarray(1).Scramble = 1;
    % bmarray(2).Scramble = 1;
    
    bmarray(2).Scramble = 1;        % Scramble the second actor
    
    %%Put the actions in different positions
    SetAllVect(bmarray,'Position3D',[-win.Width/4 0 0 ; win.Width/4 0 0]);
    %%Or you can do:
    % bm1.Position3D = [-win.Width/4 0 0];
    % bm2.Position3D = [win.Width/4 0 0];
    
    for fr = 1:1000                 
        if KbCheck                  % Check for button presses, exit if any
            break;
        end
        SetAll(bmarray, 'Rotation',pi/180); % Rotate actions 1 deg/frame
        % draw the dots, note that there is only one call to GetFrame
        moglDrawDots3D(win.Number,bmarray.GetFrame(fr),7);
        
        Screen('Flip',win.Number);  %display the dots on the screen
    end
    clear screen;
catch ME
    clear screen;
    rethrow(ME);
end