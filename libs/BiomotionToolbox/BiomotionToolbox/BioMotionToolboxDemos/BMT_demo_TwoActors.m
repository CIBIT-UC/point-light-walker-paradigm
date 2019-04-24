% The demo will show two actors that perform an interaction. It shows the
% use of setting 'Anchor' to 'none'. In most respects it works exactly as
% any single actor movie would work, except that you need two BioMotion
% objects.

clear all;                      % clear current workspace

actor1 = './actions/18_01.bvh'; % exact file location
actor2 = './actions/19_01.bvh'; % exact file location

try
    % Note that when you load two actors that were recorded when performing
    % an interaction, it is best to prevent 'Anchoring' the actions to the
    % center of the screen, in order to preserve the spatial relations
    % between the two actors. That is why the actions are initialized with
    % the 'Anchor' property set to 'none'.
    % Note also that for some motion capture libraries the actions are not
    % centered on (0,0,0), or that the units are different, and thus that
    % the actor is very big or small on the screen. It is very well
    % possible that both action will not actually fit on the screen, or
    % even that all dots fall off the screen. Therefore, when nothing is
    % visible with 'Anchor' set to 'none', always check if the call to
    % GetFrame does not give very big (positive of negative) numbers. If it
    % does, move both actors with the propertie 'Position3D' or 'Scale'
    % them.
    bm = BioMotion(actor1,'Anchor','none');     % load the data
    bm.RotatePath(pi/2);        % Rotate the action sequence so we look on the side
    bm.Loop = 1;                % Set the parameter to Loop
    
    bm2 = BioMotion(actor2,'Anchor','none');    % load the data
    bm2.RotatePath(pi/2);
    bm2.Loop = 1;               % Set the parameter to Loop
    bmarray = [bm bm2];
    
    bm.Position3D = [30 0 0];   % for some reason the actions are not
                                % completely aligned, so one is moved
                                % closer to the other.
    win = SetScreen('OpenGL',1);% Open a screen
    SetProjection(win);
    
    for fr = 1:bm.nFrames       % Run through frames 1 until the end
        if KbCheck              % Check for button presses, exit if any
            break;
        end
        moglDrawDots3D(win.Number,bmarray.GetFrame(fr),7); % draw the dots, note the call %to GetFrame
        Screen('Flip',win.Number);  %display the dots on the screen
    end
    clear screen;
catch ME
    clear screen;
    rethrow(ME);
end