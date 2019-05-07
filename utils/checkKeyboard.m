function isEscPressed = checkKeyboard()
isEscPressed=0;
[keyisdown, secs, keycode] = KbCheck;
key_esc=find(keycode);
if keyisdown == 1 & key_esc==KbName('ESCAPE')
    Screen('CloseAll');
    IOPort('CloseAll');
    ShowCursor;
    Priority(0);
    isEscPressed = 1;
end