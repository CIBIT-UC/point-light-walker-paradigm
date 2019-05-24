function m = meanwithnans(invect)
%Nanmean will calculate the mean, while ignoring any NaN values.

nanposlogic = isnan(invect);
invect(nanposlogic) = 0; %put to zeros, so can sum over them later on
sumnonnan = sum(~nanposlogic);  %number of non-NaNs, used for division later on
sumnonnan(sumnonnan==0) = NaN; 
m = sum(invect) ./ sumnonnan; %calulate mean
