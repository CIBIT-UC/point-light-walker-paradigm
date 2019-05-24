%% INIT

% Clear Workspace.
clear;
close all;
sca;

% Presets.
addpath(genpath('libs'))
addpath(genpath('utils'))

%% CONFIGS

% Define if debugging.
DEBUG=1;
% 1 to send triggers through port conn
PORTTRIGGER = 0;
% choose between 1 - lptwrite (32bits); or 2 - IOport (64bits);
SYNCBOX = 2;

if ~DEBUG
    if PORTTRIGGER
        if SYNCBOX == 1
            portAddress = hex2dec('E800'); %-configure paralell port adress
        elseif SYNCBOX == 2
            ioObj = io64;
            status = io64(ioObj);
            portAddress = hex2dec('378'); %-configure paralell port adress
        end
    end
end

%% Stimuli variables

% BACKGROUND contrast (relative to white)? (ver Gabriel)
bgDefault=.4;
BACKGROUNDCOLOR=[(round(bgDefault*255)),...
    (round(bgDefault*255)),...
    (round(bgDefault*255))];

pixelSize=3;

numActivationBlocks=24;     % Define the number of stim presentations.
biologicalMotionRate=.25;   % Define rate of biological motion stim.
stimDuration=250;           % In miliseconds.

messageLog=[];              % initiate log variables.
timeLog=[];                 % initiate log variables.

accFactor=2;                % Acceleration factor (jump through motion samples).
sizeFactor=1.5;             % Increase size of the display area.

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
    Screen('TextSize', win.Number, 60);

    DrawFormattedText( win.Number, 'Press any key.', 'center',...
        yCenter , white);
    
    % Flip to the screen
    Screen('Flip',win.Number);
    
    % Now we have drawn to the screen we wait for a keyboard button press (any
    % key) to terminate the demo
    KbStrokeWait;
    
    pause(2),
    
    if ~DEBUG
        HideCursor,
    end
    
    % ---- Set START timestamp. ----
    startTime=GetSecs;
    
    
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
            message=bm.Scramble+1; % scrambled == 2, human motion == 1;
            success=sendTrigger(PORTTRIGGER, portAddress, SYNCBOX, ioObj, message);
        end
        timeLog(end+1)=GetSecs-startTime;
        messageLog(end+1)=bm.Scramble+1;
        
        % Present stimuli.
        for fr = 1:stimDurationInSeconds*60 %bm.nFrames % Run through frames 1 until the end.
            if KbCheck                      % Check for button presses, exit if any.
                break;
            end
            % draw the dots, note the call %to GetFrame.
            moglDrawDots3D(win.Number,bm.GetFrame(fr*accFactor)*sizeFactor,pixelSize);
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
    
    if ~DEBUG
        ShowCursor,
    end
catch ME
    clear screen;
    ShowCursor,
    rethrow(ME);
end






