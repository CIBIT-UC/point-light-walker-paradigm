function [escPressed] = waitFor(pauseDuration)
escPressed=0;

start=GetSecs;

while (GetSecs-start < pauseDuration)
    escPressed=checkKeyboard();
    if escPressed
        break;
    end
end

end