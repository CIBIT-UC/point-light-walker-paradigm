
clear all, 
close all,
clc


addpath(genpath('libs\ParallelPortLibraries'))
addpath(genpath('utils'))


% --------------------------------------------------------------------
%                  Port and Trigger Settings
% --------------------------------------------------------------------

% 1 to send triggers through port conn.
PORTTRIGGER = 1;

% choose between 1 - lptwrite (32bits); or 2 - IOport (64bits).
SYNCBOX = 2;

if PORTTRIGGER
    if SYNCBOX == 1
       
        % Configure paralell port adress.
        portAddress = hex2dec('E800'); 
    elseif SYNCBOX == 2
      
        ioObj = io64;
        status = io64(ioObj);
        % Configure paralell port adress.
        portAddress = hex2dec('378'); 
        io64(ioObj, portAddress, 1);
        pause(0.01);
        io64(ioObj, portAddress, 0);
    end
end



%% -----

message=1;

success = sendTrigger(PORTTRIGGER, portAddress, SYNCBOX, ioObj, message);