% BMT_demo_1_Basic is one of the most basic programs. It initializes a bvh
% file (with the 'wrong' extension 'txt'), and then shows it.

clear all;                          % clear current workspace
 
combiname = './actions/19_01.txt';   % exact file location
 
win = SetScreen('OpenGL',1, 'Window', 1 );        % Open a screen
SetProjection(win);                 % Set the type of projection 
 
try   
    bm = BioMotion(combiname,'Filetype','bvh'); % load the data, tell the function %that you have a bvh file even though the extension is txt
    bm.Loop = 1;                % Set the parameter to Loop
        
    for fr = 1:bm.nFrames           % Run through frames 1 until the end
        if KbCheck                  % Check for button presses, exit if any
            break;
        end
        moglDrawDots3D(win.Number,bm.GetFrame(fr),7); % draw the dots, note the call %to GetFrame 
        Screen('Flip',win.Number);  %display the dots on the screen
    end    
    clear screen;
catch ME
    clear screen;
    rethrow(ME);
end