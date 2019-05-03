%% INIT

% Clear Workspace.
clear;
close all;
sca;

% Presets. 
addpath(genpath('libs\BiomotionToolbox\BiomotionToolbox'))


%% Stimuli variables

% Define if debugging.
DEBUG=1;

% configure paralell port adress.
PORTADDRESS=888;

% background contrast (relative to white)? (ver Gabriel)
BACKGROUNDCOLOR=[.4 .4 .4];


% Number of complete repetition loops presented.
pixelSize=2;
biologicalMotionRate=.25;
numRepetitions=12;

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

pause(1)
try   
    % Load action.
    % FileType: bvh.
    bm=BioMotion(stimFullPath,'Filetype','bvh'); 
        
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
            bm.Rotation=(round(rand(1)*50));
        end
        
        % bm.ScrambleOffsets=(rand(((size(bm.ScrambleOffsets))))-.5) * 150;
        

        for fr = 1:15%bm.nFrames      % Run through frames 1 until the end.
            if KbCheck                % Check for button presses, exit if any.
                break;
            end
            % draw the dots, note the call %to GetFrame.
            moglDrawDots3D(win.Number,bm.GetFrame(fr*2),pixelSize); 
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






