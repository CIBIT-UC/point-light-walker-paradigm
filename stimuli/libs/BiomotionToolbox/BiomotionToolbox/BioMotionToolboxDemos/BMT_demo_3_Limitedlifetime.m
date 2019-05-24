% The BMT_demo_3_Limitedlifetime demo shows how to make limited lifetime
% stimuli. It shows how to make limited lifetime stimuli as in Beintema &
% Lappe (2002), that is on the limb segments connecting the joints. It also
% shows how to draw limited lifetime stimuli by randomly drawing joints
% (and thus not between the joints).
try
    skel = [2 3; 3 4; 5 6; 6 7; 8 9; 9 10; 11 12; 12 13];
    
    bm = BioMotion('./actions/walker.txt');    
    bm.Loop=1;
    bm.Rotation = pi/2;
    
    bm2 = Copy(bm);
    bm2.Position3D = [200 0 0];
     
    % Limited lifetime, dots drawn along limb segments (c.f. Beintema &
    % Lappe (2002)
    bm.Skeleton = skel;
    bm.SetLimitedLifeParameters('ndots',5,'maxlife',2);
    
    % Limited lifetime, dots drawn on joint only. Need to decrease 'ndots'
    % to <nPointLights, in order to see the effect
    bm2.SetLimitedLifeParameters('ndots',4,'maxlife',2);
    
    bmarray = [bm bm2];
    SetAll(bmarray,'LimitedLife',1);
    
    win = SetScreen('OpenGL',1);
    SetProjection(win);
  
    for fr  = 1:500
        while KbCheck
        end
        moglDrawDots3D(win.Number,bmarray.GetFrame(fr),7,[255 0 0],[],2);
        Screen('Flip',win.Number);
    end
    clear screen
    
catch ME
    clear screen
    rethrow(ME);
end