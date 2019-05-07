%% INIT

% Clear Workspace.
clear;
close all;
sca;

% Presets.
addpath(genpath('libs\BiomotionToolbox\BiomotionToolbox'))
addpath(genpath('libs\ParallelPortLibraries'))
addpath(genpath('utils'))


%% Stimuli variables

% Define if debugging.
DEBUG=1;

% 1 to send triggers through port conn
PORTTRIGGER = 1;

% choose between 1 - lptwrite (32bits); or 2 - IOport (64bits);
SYNCBOX = 2;

if ~DEBUG
    if PORTTRIGGER
        if SYNCBOX == 1
            ioObj = [];
            portAddress = hex2dec('E800'); %-configure paralell port adress
        elseif SYNCBOX == 2
            
            ioObj = io64;
            status = io64(ioObj);
            portAddress = hex2dec('378'); %-configure paralell port adress
        end
    end
end

% BACKGROUND contrast (relative to white)? (ver Gabriel)
bgDefault=.4;
BACKGROUNDCOLOR=[(round(bgDefault*255)),...
    (round(bgDefault*255)),...
    (round(bgDefault*255))];

% Number of complete repetition loops presented.
pixelSize=3;
numActivationBlocks=8;          % Define the number of stim presentations.
biologicalMotionRate=.5;   % Define rate of biological motion stim.
stimDuration=5000;         % In miliseconds.

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


try
    % Load action.
    % FileType: bvh.
    bm=BioMotion(stimFullPath,'Filetype','bvh');
    
    bm.Loop=2;
    
    % --- Preparation. ---
    
    % Get the centre coordinate of the window
    xCenter = win.Center(1);
    yCenter = win.Center(2);
    
    % --- Cross defaults. ---
    
    % Here we set the size of the arms of our fixation cross
    fixCrossDimPix = 40;
    
    % Now we set the coordinates (these are all relative to zero we will let
    % the drawing routine center the cross in the center of our monitor for us)
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    
    % Set the line width for our fixation cross
    lineWidthPix = 4;
    
    
    % --- Text to display. ---
    % Draw text in the middle of the screen in Courier in white
    Screen('TextSize', win.Number, 80);
    Screen('TextFont', win.Number, 'Courier');
    DrawFormattedText( win.Number, 'Press any key.', 'center',...
        yCenter , white);
    
    % Flip to the screen
    Screen('Flip',win.Number);
    
    % Now we have drawn to the screen we wait for a keyboard button press (any
    % key) to terminate the demo
    KbStrokeWait;
    
    pause(1),
    
    % ---- Set START timestamp. ----
    startTime=GetSecs;
    
    % Send Trigger
    if ~DEBUG
        % Baseline == 2.
        message=2; 
        success=sendTrigger(PORTTRIGGER, portAddress, SYNCBOX, ioObj, message);
    end
    
    % - Present first baseline. -
    
    % Draw the fixation cross in white, set it to the center of our screen and
    % set good quality antialiasing
    Screen('DrawDots', win.Number, [xCenter yCenter], 2, white, [], 2);
    
    % Flip to the screen
    Screen('Flip',win.Number);
    
    waitFor(5-(GetSecs-startTime));
    
    fprintf('--duration of instance %i, condition %s, time since start %.3f \n',...
        0,...
        'baseline',...
        GetSecs-startTime)
    
    
    % ---- Present first baseline.
    
    for n=1:numActivationBlocks
        % Determine condition.
        if rem(n,1/biologicalMotionRate)~=0
            bm.Scramble=1;
            bm.ScramblePositions;
            condition='scrambled';
        else
            bm.Scramble=0;
            condition='human motion';
            bm.Rotation=(round(rand(1)*360));
        end
        
        % Send trigger.
        if ~DEBUG
            message=bm.Scramble; % scrambled == 1, human motion == 0;
            success=sendTrigger(PORTTRIGGER, portAddress, SYNCBOX, ioObj, message);
        end
        
        % Present stimuli.
        for fr = 1:stimDurationInSeconds*60 %bm.nFrames % Run through frames 1 until the end.
            if KbCheck                      % Check for button presses, exit if any.
                break;
            end
            % Draw the dots, note the call %to GetFrame.
            moglDrawDots3D(win.Number,bm.GetFrame(fr),pixelSize);
            % Display the dots on the screen.
            Screen('Flip',win.Number);
        end
        
        % Print to command line.
        fprintf('--duration of instance %i, condition %s, rotation %i, time since start  %.3f \n',...
            n,...
            condition,...
            bm.Rotation,...
            GetSecs-startTime)
        
        % ---- Baseline. ----
        % Send trigger with condition val.
        if ~DEBUG
            message=2; 
            success=sendTrigger(PORTTRIGGER, portAddress, SYNCBOX, ioObj, message);
        end
        
        % Draw the fixation cross in white, set it to the center of our screen and
        % set good quality antialiasing
        Screen('DrawDots', win.Number, [xCenter yCenter], 2, white, [], 2);
        % Flip to the screen
        Screen('Flip',win.Number);
        waitFor(((n*10)+5)-(GetSecs-startTime));
        
        % Print to command line.
        fprintf('--duration of instance %i, condition %s, time since start %.3f \n',...
            n,...
            'baseline',...
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






