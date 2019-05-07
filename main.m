%% INIT

% Clear Workspace.
clear;
close all;
sca;

% Presets. 
addpath(genpath('libs\BiomotionToolbox\BiomotionToolbox'))
addpath(genpath('libs\ParallelPortLibraries'))


%% Stimuli variables

% Define if debugging.
DEBUG=1;

% configure paralell port adress.
PORTADDRESS=888;

% 1 to send triggers through port conn
PORTTRIGGER = 0;

% choose between 1 - lptwrite (32bits); or 2 - IOport (64bits);
SYNCBOX = 2;

if PORTTRIGGER
    if SYNCBOX == 1
   
        PortAddress = hex2dec('E800'); %-configure paralell port adress
    elseif SYNCBOX == 2
      
        ioObj = io64;
        status = io64(ioObj);
        PortAddress = hex2dec('378'); %-configure paralell port adress
        data_out=1;
        io64(ioObj, PortAddress, data_out);
        data_out=0;
        pause(0.01);
        io64(ioObj, PortAddress, data_out);
    end
end



% BACKGROUND contrast (relative to white)? (ver Gabriel)
bgDefault=.4;
BACKGROUNDCOLOR=[(round(bgDefault*255)),...
    (round(bgDefault*255)),...
    (round(bgDefault*255))];


% Number of complete repetition loops presented.
pixelSize=3;
numRepetitions=8;          % Define the number of stim presentations.
biologicalMotionRate=.5;   % Define rate of biological motion stim.
stimDuration=8000;         % In miliseconds.


%% Stimuli definition
stimDurationInSeconds=stimDuration/1000;

% --- STIM ---
% Define stim action.
stimFullPath=fullfile(pwd,'libs','BiomotionToolbox','BiomotionToolbox',...
    'BiomotionToolboxDemos','actions','19_01.bvh'); % exact file location

% --- SCREEN ---
% Skip sync tests for this demo in case people are using a defective
% system. This is for demo purposes only.
Screen('Preference', 'SkipSyncTests', 2);
% Find the screen to use for displaying the stimuli.
screenid=1;
% Determine the values of black and white
black=BlackIndex(screenid);
white=WhiteIndex(screenid);
% Open a screen.
win=SetScreen(  'OpenGL', 1,...
                'Window', screenid,...
                'BGColor', BACKGROUNDCOLOR); 
% Set the type of projection.
SetProjection(win);                             

pause(1)
try   
    % Load action.
    % FileType: bvh.
    bm=BioMotion(stimFullPath,'Filetype','bvh'); 
    
    bm.Loop=2;
        
    % Set beggining timestamp.
    startTime=GetSecs;
    
    for n=1:numRepetitions
        
        if rem(n,1/biologicalMotionRate)~=0
            bm.Scramble=1;
            bm.ScramblePositions;
            condition='scrambled';
        else
            bm.Scramble=0;
            condition='human motion';
            bm.Rotation=(round(rand(1)*360));
        end
        

        for fr = 1:stimDurationInSeconds*60 %bm.nFrames % Run through frames 1 until the end.
            if KbCheck                      % Check for button presses, exit if any.
                break;
            end
            % draw the dots, note the call %to GetFrame.
            moglDrawDots3D(win.Number,bm.GetFrame(fr),pixelSize); 
            % Display the dots on the screen.
            Screen('Flip',win.Number); 
        end
        
        fprintf('--duration of instance %i, condition %s, rotation %i, was %.3f \n',...
            n,...
            condition,...
            bm.Rotation,...
            GetSecs-startTime)
        
    end
    
    % Set end timestamp.
    endTime=GetSecs-startTime;
    fprintf('--duration of the protocol was %.3f \n', endTime)
    
    Screen('Flip',win.Number); 
    
    clear screen;
catch ME
    clear screen;
    rethrow(ME);
end






