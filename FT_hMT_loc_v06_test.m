% function FT_hMT_loc
% Localizer using frequency-tagging with motion direction change and
% contrast modulation at distinct frequencies. Initial version March2018 GC
% 30.Jan.2019 I'm testing this to run an experiment with

% set maximum priority
Priority(2);

% Clear Workspace
clear;
close all;
sca;

% Unify key names for common naming scheme for all operating systems
KbName('UnifyKeyNames');

%-configure paralell port adress
PortAddress = 888;
% PortAddress = hex2dec('378');

% Skip sync tests for this demo in case people are using a defective
% system. This is for demo purposes only.
Screen('Preference', 'SkipSyncTests', 2);

% --------------------------------------------------------------------
%                  Screen Settings and parameters
% --------------------------------------------------------------------

% Find the screen to use for displaying the stimuli.
screenid = max(Screen('Screens'));

% Determine the values of black and white
black = BlackIndex(screenid);
white = WhiteIndex(screenid);

% Determine screen resolution
rect = Screen('Rect', screenid);
xres = rect(3);
yres = rect(4);

% determine screen center in x and y
xcenter = ceil(xres/2);
ycenter = ceil(yres/2);

% determine screen framerate
frate = Screen('FrameRate',screenid);

% background contrast (relative to white)
backcontrast = 0.4;

% thickness of fixation cross
crossthick = 4;

% --------------------------------------------------------------------
%                  Port and Trigger Settings
% --------------------------------------------------------------------

% 1 to send triggers through port conn
portTrigg = 0;

% choose between 1 - lptwrite (32bits); or 2 - IOport (64bits);
syncbox = 2;

if portTrigg
    if syncbox == 1
        addpath('./ParallelPortLibraries/');
        PortAddress = hex2dec('E800'); %-configure paralell port adress
    elseif syncbox == 2
        addpath('./ParallelPortLibraries/');
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

% --------------------------------------------------------------------
%                  Experiment Settings
% --------------------------------------------------------------------

% protocol time (sec)
protoTime = 120;

% 1 for different translations; 2 for identical translation; 3 for rigid
% rotations alternating with random motion
stimCond = 1;

% 1 for static frame between different motion; 0 for no static frame
framestop = 0;
% number of frame to appear static
nstopframe = 2;
% set if to present center (0), left (1), or right (2);
stimpos = 0;

% stimulus distance from center
stimdist = 430; % in pix (FIX THIS LATER)

if stimpos ~= 0 && stimdist ~= 0
    if stimpos == 1
        xcenter2 = xcenter;
        xcenter = xcenter + stimdist;
    elseif stimpos == 2
        xcenter2 = xcenter;
        xcenter = xcenter - stimdist;
    end
else
    xcenter2 = xcenter;
end

% % gaussian transition. 1 for stimulation with a oscillating gaussian
% % background luminance; 0 for direct changes without gaussian background luminance
% % modulation
% gausstrans = 1;

% ..................................................................
%                         Stimuli parameters
% ..................................................................

% to show stimulus on a gaussian window (1) or to show stimulus on an
% gaussian window with oscilating luminance (2);
gausswin = 2;
% Set gaussian window size to medium
winSize = 1;

% rectangular or ciruclar window
rectwin = 0;
% radius of gaussian window in pix (CHANGE!)
radius = 300;

% scale of the stimulus (? unknown why for now)
stim_scale = 1;

% length, horizontal, and height of stimulus shown (pix)
largura = 800;
altura = 800;

% number of dots to display
dots.numb = 1200;

% size of dots (radius in px)
dots.size = 6 * stim_scale;
% contrast of dots relative to white (1)
dots.contrast = 1;

% dots motino speed (in pix CHANGE!)
motspeed = 5;
% set initial speed as current speed
currSpeed = motspeed;

% angle of dots rotation
angleRot = 0.9;

% rate of motion direction change
freqmot = 5;   % in Hz (change/sec)

% rate of dots size change
freqdotsz = 3; % in Hz (change/sec)

% rate of luminance change
freqlum = 4;   % in Hz (change/sec)

% 0 for constant motion; 1 for oscillatory motion (accelerating and
% decelerating)
motosci = 0;

% reset dots position when reaching lifetime (2), every motion change (1) or never (0), making dots move
% continuously (only reset when breaching border limits)
resetdots = 1;

% maximum lifetime of each dot (in frames)
maxlifet = 40;

% vector with all lifetimes
vectlife = randi(maxlifet, 1, dots.numb);

% percentage of dots to change every iteration
percchange = 0;

% ----------------------------------------------------------------------
%                        Set dots positions
% ----------------------------------------------------------------------

% valid dots position
dots.posx = xcenter-largura/2:1:xcenter+largura/2;
dots.posy = ycenter-altura/2:1:ycenter+altura/2;

% window limits to define inbounds and outbounds dots
winlimX(1,1) = min(dots.posx);
winlimX(1,2) = max(dots.posx);
winlimY(1,1) = min(dots.posy);
winlimY(1,2) = max(dots.posy);

% set color/contrast of dots
dots.color = [(255*dots.contrast) (255*dots.contrast) (255*dots.contrast)];

% set position of dots
dots.center = rand(dots.numb,2); % obtain an amount "dots.numb" of random positions (goes from 0 to 1 but I multiply by the images dimensions and "floor" it for integers)
dots.center(:,1) = floor((dots.center(:,1)* (largura))+(xcenter - largura/2));  % multiply centers by the dimension "largura" and add xcenter-largura, so image is at left of the center
dots.center(:,2) = floor((dots.center(:,2) * altura)+(ycenter - altura/2)); % this one has to be /2 so that half is above and half below the ycenter
dots.center = transpose(dots.center); % since values are in two columns I have to transpose to lines

dots.startx = xcenter-largura;
dots.starty = ycenter-altura/2;

% -----------------------------------------------------------------------
%                      Set fixation cross
% -----------------------------------------------------------------------

% set fixation cross points
FixCross = [xcenter2-(sqrt(crossthick)),ycenter-(2*sqrt(crossthick)),xcenter2+(sqrt(crossthick)),ycenter+(2*sqrt(crossthick));...
    xcenter2-(2*sqrt(crossthick)),ycenter-(sqrt(crossthick)),xcenter2+(2*sqrt(crossthick)),ycenter+(sqrt(crossthick))]; % Draw Central Cross

% -----------------------------------------------------------------------
%                  Settings gaussian window
% -----------------------------------------------------------------------

% variation in radius of gaussianwindow
radvar = 0;

windowM = ones(xres,yres);
windowM = windowM * 255;
windowS = windowM;
windowL = windowM;

if rectwin
    windowM((xcenter-largura*0.9):(xcenter+largura*0.9),(ycenter-altura/2):(ycenter+altura/2))=1;
else
    for pix = 1:xres
        for piy = 1:yres
            if (pix - xcenter)^2 + (piy - ycenter)^2 <= radius^2
                windowM(pix,piy) = 1;
            end
            if (pix - xcenter)^2 + (piy - ycenter)^2 <= (radius*(1-radvar))^2
                windowS(pix,piy) = 1;
            end
            if (pix - xcenter)^2 + (piy - ycenter)^2 <= (radius*(1+radvar))^2
                windowL(pix,piy) = 1;
            end
        end
    end
end

transLayer = 2;

% MY CODE

% create the grid of (x,y) values
mySize=[ceil(largura/8), ceil(largura/8)];
myStd=ceil(largura/16);
mySize = (mySize-1)./2;
% create the grid of (x,y) values
[myX,myY] = meshgrid(-mySize(2):mySize(2),-mySize(1):mySize(1));
% analytic function
myH = exp(-(myX.*myX + myY.*myY)/(2*myStd*myStd));
% truncate very small values to zero
myH(myH<eps*max(myH(:))) = 0;
% normalize filter to unit L1 energy
mySumh = sum(myH(:));
if mySumh ~= 0
    myH = myH/mySumh;
end
gausswindowM(:,:,transLayer) = uint8(conv2(windowM', myH,'same'));
gausswindowM(:,:,1) = gausswindowM(:,:,1) +255*backcontrast;
gausswindowS(:,:,transLayer) = uint8(conv2(windowS', myH,'same'));
gausswindowS(:,:,1) = gausswindowS(:,:,1) +255*backcontrast;
gausswindowL(:,:,transLayer) = uint8(conv2(windowL', myH,'same'));
gausswindowL(:,:,1) = gausswindowL(:,:,1) +255*backcontrast;

gausswindowfull = gausswindowM(:,:,transLayer)*0 +255;
% --------------------------------------------------------------------- %
%                get variations of gaussian transparency
% --------------------------------------------------------------------- %

% get gaussian-like curve (written by RM)
x = [0:0.01:5];
myMean=2.5; %(onde atinge o maximo)
myStd=1;
y01 = normpdf(x,myMean,myStd);
y02=(y01-y01(1));
myYscale=1/max(y02);
y03=y02*myYscale;
y03= 1-y03;


% Set margins (to appear beyond the gaussian window
sidesize = altura/8;
Sides = [(xcenter-(largura)),(ycenter-altura/2),(xcenter-(largura+sidesize)),(ycenter+(altura/2));...
    (xcenter+(largura)), (ycenter-(altura/2)), (xcenter+largura+sidesize) (ycenter+(altura/2))];
% measures of the rectangle that frame the stimuli (in black) at the
% sides

UpDownSides = [(xcenter-1.5*largura),(ycenter-(1.5*altura+sidesize)),(xcenter+1.5*largura),(ycenter-altura/2);...
    (xcenter-1.5*largura), (ycenter+altura/2), (xcenter+1.5*largura) (ycenter+(1.5*altura+sidesize))];
% measures of the rectangle that frame the stimuli (in black) at the
% uppder and lower part of the stimulus

Margins = [Sides; UpDownSides];
% To create the margins that frame the stimulus

% ----------------------------------------------------------------------
%                        Screen Initialisation
% ----------------------------------------------------------------------

% Open a fullscreen window and set it to black
[windowID rect] = Screen('OpenWindow', screenid, [255*backcontrast 255*backcontrast 255*backcontrast], []);
%     [windowID rect] = Screen('OpenWindow', screenNumber, 0, [500 100 1500 1000]);

% Set the blend function so that we get nice antialised edges to the dots
Screen('BlendFunction', windowID, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% ----------------------------------------------------------------------
%                     Show pre-stimulus window
% ----------------------------------------------------------------------

% Set letter size
Screen('TextSize', windowID , 80);
% Show initial/ready screen
Screen('DrawText', windowID, 'Ready...', xres/2.5, yres/2.2, [200 200 200]);
frametime = Screen('Flip',windowID);
WaitSecs(2)


% get the total number of frames the stimulus will have
totalFr = protoTime * frate;
% get number of frames to elapse between changes
numFr_change = ceil(1/freqmot * frate);
% get all frames where change is to occur
changeFr = numFr_change:numFr_change:totalFr;

% get number of frames to be stopped
for istop = 1:nstopframe
    if framestop
        if istop == 1
            stopFr = changeFr +istop-1;
        else
            stopFr = [stopFr changeFr+istop-1];
        end
    else
        stopFr = changeFr * 0;
    end
end

% % % % % % % % % % % % % % % % % % % % % gausswindowM(:,:,2) = gausswindowM(:,:,2); % FOR TESTING WINDOWS PURPOSES

cyclestart = 1;
cyclecenter = numFr_change/2 + 1;
cycleint    = (numFr_change - 2)/2;

cyclevars = floor((length(y03)/2)/(cycleint+2));
cycleTrans = 1:cyclevars:255;
cycleTrans(1) = 1;
cycleTrans(2) = [];
cycleTrans(length(cycleTrans)) = 255;
cycleTrans = [cycleTrans cycleTrans(end-1:-1:2)];

switch gausswin
    case 1
        iwin = 1;
        windowtextM = Screen('MakeTexture', windowID, gausswindowM);
        windowtextS = Screen('MakeTexture', windowID, gausswindowS);
        windowtextL = Screen('MakeTexture', windowID, gausswindowL);
    case 2
        for idwin = 1:numFr_change
            gaussCurr = double(gausswindowM);
            gaussCurr(:,:,2) = gaussCurr(:,:,2) + 255*y03(cycleTrans(idwin));
            gaussMat(:,:,idwin) = gaussCurr(:,:,2);
            gaussCurr = uint8(gaussCurr);
            windowtextW(idwin) = Screen('MakeTexture', windowID, gaussCurr);
        end
        iwin = 1;
        wincycle = 1:(length(windowtextW));
        increment = 1;
end

% Cycle of gradual speed changes
if motosci
    cycleMot = cycleTrans/255;
else
    cycleMot = ones(1, length(cycleTrans));
end
increment = 1;

% ---------------------------------------------------------------------
%                           Start experiment
% ---------------------------------------------------------------------

% Set initial time at the start of the stimulation
startTime = GetSecs;
% Set initial time of a condition
initTime = startTime;
% Get current time
currentTime = initTime - GetSecs;
% Set time for experiment to be complete
endTime = currentTime + protoTime;

% set matrix to get all timepoints of motion change
matpress = [];

% Set initial frame counter
currentFr = 1;

% get a random initial direction
if stimCond == 1 || stimCond == 4
    idirect = randi(8,1);
elseif stimCond == 2
    idirect = randi(8,1);
elseif stimCond == 3
    idirect= 10;
end

% set initial variables of random dot direction
% refresh random direction
randir  = rand(1, numel(dots.center(1,:)),1);
randirx = round(randir,1);
randiry = 1-round(randir,1);

posnegmatx =  -(ones(numel(dots.center(1,:)),1));
randmatx = randi([0 1], length(posnegmatx),1);
posnegmatx = posnegmatx.^randmatx;
posnegmatx =  posnegmatx';

randmaty = randi([0 1], length(posnegmatx),1);
posnegmaty = posnegmatx'.^randmaty;
posnegmaty =  posnegmaty';

randirx = randirx.*posnegmatx;
randiry = randiry.*posnegmaty;


% Send trigger right before the experiment starts
if portTrigg
    if syncbox==1
        lptwrite(PortAddress, 35);
        WaitSecs(0.004);
        lptwrite(PortAddress, 0);
    elseif syncbox==2
        io64(ioObj, PortAddress, 35);
        WaitSecs(0.004);
        io64(ioObj, PortAddress, 0);
    end
end

% get initial time
nchange = 1;
matpress(nchange, 1) = 35;
matpress(nchange,2) = initTime - GetSecs;

while currentTime < endTime
    % Start showing dots
    Screen('DrawDots', windowID, dots.center, dots.size, dots.color, [], 1);
    
    % --------------------------------------------------------------- %
    %                update dots direction and position
    % --------------------------------------------------------------- %
    if ismember(currentFr, changeFr)
        iwin = 1;
        increment = 1;
        %         currentFr
        %         disp('ch')
        prevdirect= idirect;
        
        if stimCond == 1
            % for different translations
            idirect = randi(8,1);
            checkdir = 1;
        elseif stimCond == 2
            % for identical translations
            idirect = idirect;
            checkdir = 0;
        elseif stimCond == 3
            % for random and rigid rotations
            if prevdirect == 10
                idirect = 11;
            elseif prevdirect == 11
                idirect = 10;
            else
                idirect = 11;
            end
            checkdir = 0;
            theta = angleRot * (-1)^randi(2,1);
        elseif stimCond == 4
            % for random vs coherent translations
            if prevdirect == 10
                idirect = randi(8,1);
                checkdir = 1;
            else
                idirect = 10;
                checkdir = 0;
            end
        end
        
        while checkdir == 1
            if idirect == prevdirect
                idirect = randi(8,1);
            else
                checkdir = 0;
            end
        end
        
        
        %         idirect = 5;
        %         directions(currentFr,1) = idirect;
        %         directions(currentFr,2) = currentFr;
        
        %         % refresh dots position
        if resetdots == 1
            dots.center(1,:) =  dots.posx(randi(numel(dots.posx),1,dots.numb));
            dots.center(2,:) =  dots.posy(randi(numel(dots.posy),1,dots.numb));
            %         dots.size = randi([5 10],1);
        else
        end
        
        % refresh random direction
        randir  = rand(1, numel(dots.center(1,:)),1);
        randirx = round(randir,1);
        randiry = 1-round(randir,1);
        
        posnegmatx =  -(ones(numel(dots.center(1,:)),1));
        randmatx = randi([0 1], length(posnegmatx),1);
        posnegmatx = posnegmatx.^randmatx;
        posnegmatx =  posnegmatx';
        
        randmaty = randi([0 1], length(posnegmatx),1);
        posnegmaty = posnegmatx'.^randmaty;
        posnegmaty =  posnegmaty';
        
        randirx = randirx.*posnegmatx;
        randiry = randiry.*posnegmaty;
        
        if portTrigg
            % send trigger with the new motion direction
            if syncbox==1
                lptwrite(PortAddress, idirect);
                WaitSecs(0.004);
                lptwrite(PortAddress, 0);
            elseif syncbox==2
                io64(ioObj, PortAddress, idirect);
                WaitSecs(0.004);
                io64(ioObj, PortAddress, 0);
            end
        end
        
        % Get the time of change all direction changes
        
        changeTime = GetSecs - startTime;
        
        nchange = nchange + 1;
        matpress(nchange, 1) = idirect;
        matpress(nchange,2) = currentFr;
        
    end
    
    % --------------------------------------------------------------- %
    %              renew dots that have reached max lifetime
    % --------------------------------------------------------------- %
    
    if resetdots == 2
       vectlife = vectlife + 1;
       dotsdead = find(vectlife > maxlifet);
       
       vectlife(dotsdead) = 1;
       
    end
    
    % --------------------------------------------------------------- %
    %                update gaussian window transparency/contrast
    % --------------------------------------------------------------- %
    
    switch gausswin
        case 0
            Screen('FillRect', windowID, [0 0 0], Margins');
        case 1
            if ismember(currentFr, changeFr)
                winSize = randi(3,1);
            else
            end
            if winSize == 1
                Screen('DrawTexture', windowID, windowtextM);
            elseif winSize == 2
                Screen('DrawTexture', windowID, windowtextS);
            elseif winSize == 3
                Screen('DrawTexture', windowID, windowtextL);
            end
        case 2
            Screen('DrawTexture', windowID, windowtextW(iwin))
            %             if iwin == max(wincycle)
            % %                 iwin = 0;
            %                 increment = -1;
            %                 nchange = nchange + 1;
            %                 matpress(nchange, 1) = 101;
            %                 matpress(nchange,2) = currentFr;
            %                 %                 Screen('DrawText', windowID, '101...', xres/2.5, yres/2.2, [200 200 200]);
            %                 iwin
            %                 wincycle(iwin)
            %                 KbWait
            %             elseif iwin == min(wincycle)
            %                 increment = 1;
            %                 nchange = nchange + 1;
            %                 matpress(nchange, 1) = 100;
            %                 matpress(nchange,2) = currentFr;
            %                 %                 Screen('DrawText', windowID, '100...', xres/2.5, yres/2.2, [200 200 200]);
            %                 iwin
            %                 wincycle(iwin)
            %                 KbWait
            %             end
    end
    
    currSpeed = motspeed * cycleMot(iwin);
    % update iwin
    iwin = iwin + increment;
    if ~ismember(currentFr, stopFr)
        % motion right
        if idirect == 1
            dots.center(1,:) = dots.center(1,:) + 1*currSpeed;
            dots.center(2,:) = dots.center(2,:) + 0*currSpeed;
            % motion right-downward
        elseif idirect == 2
            dots.center(1,:) = dots.center(1,:) + 0.7*currSpeed;
            dots.center(2,:) = dots.center(2,:) + 0.7*currSpeed;
            % motion downward
        elseif idirect == 3
            dots.center(1,:) = dots.center(1,:) + 0*currSpeed;
            dots.center(2,:) = dots.center(2,:) + 1*currSpeed;
            % motion left-downward
        elseif idirect == 4
            dots.center(1,:) = dots.center(1,:) - 0.7*currSpeed;
            dots.center(2,:) = dots.center(2,:) + 0.7*currSpeed;
            % motion left
        elseif idirect == 5
            dots.center(1,:) = dots.center(1,:) - 1*currSpeed;
            dots.center(2,:) = dots.center(2,:) + 0*currSpeed;
            % motion left-upward
        elseif idirect == 6
            dots.center(1,:) = dots.center(1,:) - 0.7*currSpeed;
            dots.center(2,:) = dots.center(2,:) - 0.7*currSpeed;
            % motion upward
        elseif idirect == 7
            dots.center(1,:) = dots.center(1,:) + 0*currSpeed;
            dots.center(2,:) = dots.center(2,:) - 1*currSpeed;
            % motion right-upward
        elseif idirect == 8
            dots.center(1,:) = dots.center(1,:) + 0.7*currSpeed;
            dots.center(2,:) = dots.center(2,:) - 0.7*currSpeed;
        elseif idirect == 9
        elseif idirect == 10
            dots.center(1,:) = dots.center(1,:) + randirx*currSpeed;
            dots.center(2,:) = dots.center(2,:) + randiry*currSpeed;
        elseif idirect == 11
            dots.center(1,:) = dots.center(1,:) - xcenter;
            dots.center(2,:) = dots.center(2,:) - ycenter;
            
            R_2= [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
            dotstemp = R_2*[dots.center(1,:)' dots.center(2,:)']';
            
            dots.center(1,:) = dotstemp(1,:) + xcenter;
            dots.center(2,:) = dotstemp(2,:) + ycenter;
        end
    end
    
    % ----------------------------------------------------------------- %
    %          Get dots out of bounds and reset them
    % ----------------------------------------------------------------- %
    
    % identify dots out of bounds for +Y
    dots_outYmax = find(dots.center(2,:) > winlimY(1,2));	% dots to reposition
    noutymax = length(dots_outYmax);
    
    if noutymax
        dots.center(2, dots_outYmax) = winlimY(1,1);
    else
    end
    
    % identify dots out of bounds for -Y
    dots_outYmin = find(dots.center(2,:) < winlimY(1,1));	% dots to reposition
    noutymin = length(dots_outYmin);
    
    if noutymin
        dots.center(2, dots_outYmin) = winlimY(1,2);
    else
    end
    
    % identify dots out of bounds for +X
    dots_outXmax = find(dots.center(1,:) > winlimX(1,2));	% dots to reposition
    noutxmax = length(dots_outXmax);
    
    if noutxmax
        dots.center(1, dots_outXmax) = winlimX(1,1);
    else
    end
    
    % identify dots out of bounds for -X
    dots_outXmin = find(dots.center(1,:) < winlimX(1,1));	% dots to reposition
    noutxmin = length(dots_outXmin);
    
    if noutxmin
        dots.center(1, dots_outXmin) = winlimX(1,2);
    else
    end
    % draw dot for testing positions
    %         Screen('DrawDots', windowID, [winlimX(1,1); dots.starty], 15, [1 1 0], [], 1);
    
    % refresh dots
    if resetdots == 2
        dotschange = dotsdead;
        dots.center(1,dotschange) =  dots.posx(randperm(numel(dots.posx),numel(dotschange)));
        dots.center(2,dotschange) =  dots.posy(randperm(numel(dots.posy),numel(dotschange)));
    else
        dotschange = randperm(dots.numb, dots.numb*percchange/100);
        dots.center(1,dotschange) =  dots.posx(randperm(numel(dots.posx),numel(dotschange)));
        dots.center(2,dotschange) =  dots.posy(randperm(numel(dots.posy),numel(dotschange)));
    end
    
    % set color/contrast of dots
    %     if ismember(currentFr, changeFr)
    %         dots.contrast = randi([8 10],1)/10; % was between [8 10]
    %         dots.color = [(255*dots.contrast) (255*dots.contrast) (255*dots.contrast)];
    %     else
    %     end
    
    %
    %     % check for dots out of bound
    %     dotsum = dots.center(1,:) + dots.center(2,:);
    %     dotsfar = find(dotsum > winlim(2));
    %     dotsclose = find(dotsum < winlim(1));
    %     dotsout = [dotsfar dotsclose];
    %     if ~isempty(dotsout)
    %         dots.center(1,dotsout) =  dots.posx(randi(numel(dots.posx),1,numel(dotsout)));
    %         dots.center(2,dotsout) =  dots.posy(randi(numel(dots.posy),1,numel(dotsout)));
    %     end
    %
    currentTime = GetSecs - startTime;
    currentFr = currentFr + 1;
    
    %     [keyIsDown, secs, keyCode] = KbCheck;
    
    % -------- KEYS --------
    [~,~,keyCode] = KbCheck();
    if keyCode(KbName('escape')) == 1 %Quit if "Esc" is pressed
        Screen('CloseAll');
        ShowCursor;
        Priority(0);
        
        % Launch window with warning of early end of program
        warndlg('The task was terminated with ''Esc'' before the end!','Warning','modal')
        
        return % abort program
    end
    
    if keyCode(KbName('1!')) == 1
        idirect = 1;
    elseif keyCode(KbName('2@')) == 1
        idirect = 2;
    elseif keyCode(KbName('3#')) == 1
        idirect = 3;
    elseif keyCode(KbName('4$')) == 1
        idirect = 4;
    elseif keyCode(KbName('5%')) == 1
        idirect = 5;
    elseif keyCode(KbName('6^')) == 1
        idirect = 6;
    elseif keyCode(KbName('7&')) == 1
        idirect = 7;
    elseif keyCode(KbName('8*')) == 1
        idirect = 8;
    elseif keyCode(KbName('9(')) == 1
        idirect = 9;
    else
    end
    
    %         if keyIsDown==1
    %                 % The user asked to exit the program
    %             if keyCode(escapekeycode)
    %                 escapekeypress = 1;
    %                 % Close PTB screen and connections
    %                 Screen('CloseAll');
    %                 ShowCursor;
    %                 Priority(0);
    %
    %                 % Launch window with warning of early end of program
    %                 warndlg('The task was terminated with ''Esc'' before the end!','Warning','modal')
    %
    %                 return % abort program
    %             end
    %         end
    %     Screen('FillRect', windowID, [255*backcontrast 255*backcontrast 255*backcontrast], Margins');
    
    % Draw central fixation cross
    Screen('FillRect', windowID, [255 0 0], FixCross');
    
    frametime = Screen('Flip',windowID);
    %     WaitSecs(0.2)
end
% WaitSecs(0)

Screen('FillRect', windowID, [255*backcontrast 255*backcontrast 255*backcontrast], Margins');
% Screen('DrawDots', windowID, dots.center2, dots.size, dots.color, [], 1);
frametime = Screen('Flip',windowID);
WaitSecs(2)


Screen('CloseAll');