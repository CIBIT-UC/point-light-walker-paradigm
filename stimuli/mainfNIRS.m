%% INIT

% Clear Workspace.
clear;
close all;
sca;

% Presets.
addpath(genpath('libs\BiomotionToolbox\BiomotionToolbox'))
addpath(genpath('libs\ParallelPortLibraries'))
addpath(genpath('utils'))

%% Configs variables
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


%% Stimuli variables

% -------------------------------------------------------------- %
% default: triggers: baseline=10; human motion=11; scrambled=12; %
% -------------------------------------------------------------- %

% BACKGROUND contrast (relative to white)? (ver Gabriel)
bgDefault=.4;
BACKGROUNDCOLOR=[(round(bgDefault*255)),...
    (round(bgDefault*255)),...
    (round(bgDefault*255))];


baselineTrigger=10;             % baseline trigger val.

pixelSize=3;                    % Pixel size.

numActivationBlocks=4;          % Define the number of stim presentations.
biologicalMotionRate=.5;        % Define rate of biological motion stim.
stimDuration=5000;              % Stimuli duration in miliseconds.
stimDurationInSeconds=stimDuration/1000;
baselineDuration=8;             % Baseline duration in miliseconds.

messageLog=[];                  % Initiate log variables.
timeLog=[];                     % Initiate log variables.

accFactor=2;                    % Acceleration factor (jump through motion samples).
sizeFactor=1.5;                 % Increase size of the display area.

%% Stimuli definition

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
    
    % Send Trigger
    if ~DEBUG
        % Baseline == 2.
        message=baselineTrigger; 
        success=sendTrigger(PORTTRIGGER, portAddress, SYNCBOX, ioObj, message);
    end
    timeLog(1)=0;
    messageLog(1)=baselineTrigger; 
    
    % - Present first baseline. -
    
    % Draw the fixation cross in white, set it to the center of our screen and
    % set good quality antialiasing
    Screen('DrawDots', win.Number, [xCenter yCenter], pixelSize, white, []);
    
    % Flip to the screen
    Screen('Flip',win.Number);
    
    waitFor(baselineDuration -(GetSecs-startTime));
    
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
            message=bm.Scramble+11; % scrambled == 1, human motion == 0;
            success=sendTrigger(PORTTRIGGER, portAddress, SYNCBOX, ioObj, message);
        end
        
        timeLog(end+1)=GetSecs-startTime;
        messageLog(end+1)=bm.Scramble+11;

        
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
            message=baselineTrigger; 
            success=sendTrigger(PORTTRIGGER, portAddress, SYNCBOX, ioObj, message);
        end
        timeLog(end+1)=GetSecs-startTime;
        messageLog(end+1)=baselineTrigger;
        
        % Draw the fixation cross in white, set it to the center of our screen and
        % set good quality antialiasing
        Screen('DrawDots', win.Number, [xCenter yCenter], pixelSize, white, []);
        % Flip to the screen
        Screen('Flip',win.Number);
        waitFor(((n*(5+baselineDuration))+baselineDuration)-(GetSecs-startTime));
        
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
    
    if ~DEBUG
        ShowCursor,
    end
catch ME
    ShowCursor,
    clear screen;
    rethrow(ME);
end






