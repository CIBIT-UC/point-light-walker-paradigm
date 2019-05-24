q% This demo shows of many different uses of the BioMotionToolbox, including
% using rotation, looping, scaling, copying biomotion objects, initiating
% biomotion objects of different data types. It also shows how to use the
% BioMotionToolbox in case you do not want to use OpenGL (by setting 
% UseOpenGL to 0.

%to Exit, press any key

%Determine whether to use OpenGL. Note: the BioMotion toolbox is written
%with the screen dimensions of OpenGL in mind. So the Center of the screen
%is (0,0) and the y dimension is upwards (not downwards as in Psychtoolbox)
UseOpenGL = 0;

%additional parameters
p.dotsize = 7;

actionfolder = './actions/';

try
    %%load a c3d file, with c3d extension
    bm1 = BioMotion([actionfolder '19_01.txt'],'FileType','bvh');
    
    %%load a file, but only certain frames
    bm2 = BioMotion([actionfolder '60_06.data3d.txt'],'SelectFrames',1:100,'SelectJoints',1:10);
    
    %%load a file with a non-standard extension
    bm3 = BioMotion([actionfolder 'Playtennis.rex'],'Filetype','vanrie');
    
    %use Copy to make a copy of bm3
    bm4 = Copy(bm3);
    
    %bm1 3 and 4 are large so need to resize
    %bm1.Scale = 1/30;
    SetAll([bm3 bm4],'Scale',[1/2 0.8]);
    
    % make array
    bmarray = [bm1 bm2 bm3 bm4];
    
    %make the movies loop
    SetAll(bmarray,'Loop',1); % option 1 of SetqAll
    SetAllVect(bmarray,'Position3D',[-300 0 0;-150 0 0;150 0 0 ;300 0 0]);
    
    %make some of the movies a smooth loop
    bm2.SmoothLoop;
    bm4.SmoothLoop;
    
    %rotate the whole movie by 90 degrees
    bm4.RotatePath(pi/2);
    
    %invert movie 2 and phase scramble movie 2 and 4
    SetAll(bmarray,'Invert',1,2);               % option 3 of SetAll
    SetAll(bmarray,'PhaseScramble',[0 1 0 1]);  % option 2 of SetAll
    bmarray(1).Scramble = 1;                    % alternative way of setting propertie for single object
    
    %Set up screen
    win = SetScreen('OpenGL',UseOpenGL);
    if UseOpenGL
        SetProjection(win);
    end
    
    %start display loop
    fr = 0;
    while ~KbCheck
        fr = fr+1;
        if fr == 300
            bmarray(4).PhaseScramble = 0; %reset to no phasescramble
            bmarray(1).Scramble = 0; %reset to no Scramble
        end
        bmarray.SetAll('Rotation',pi/180);
        if fr < 600
            toshow = bmarray.GetFrame(fr);
        else
            %different frame numbers are requested for different actions
            %only joint 1 to 5 are requested
            toshow = bmarray.GetFrame(fr+[30 60 70 80],1:5);
        end
        
        if UseOpenGL
            moglDrawDots3D(win.Number,toshow,p.dotsize,[1 1 1],[],2);
        else
            toshow(2,:)=-toshow(2,:); %in OpenGL and 'normal' Psychtoolbox the y-dimensions run in opposite directions...
            toshow2 = toshow(1:2,:) + repmat(win.Center,size(toshow,2),1)';
            Screen('FillOval',win.Number,255,[toshow2-p.dotsize/2;toshow2+p.dotsize/2]);
        end
        Screen('Flip',win.Number);
    end
    clear screen
catch ME
    clear screen
    rethrow(ME);
end