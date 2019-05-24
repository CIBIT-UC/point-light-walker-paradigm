function success = sendTrigger(portTrigg,portAddress, syncBox, ioObj, message)

% Default return variable.
success = 0;

% Send trigger with "message"
if portTrigg
    if syncBox==1
        lptwrite(portAddress, message);
        WaitSecs(0.004);
        lptwrite(portAddress, 0);
        success=1;
    elseif syncBox==2
        io64(ioObj, portAddress, message);
        WaitSecs(0.004);
        io64(ioObj, portAddress, 0);
        success=1;
    end
end


end