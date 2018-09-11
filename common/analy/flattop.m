function iRange = flattop(dbData,dbStartPercent,dbIncreasment,dbDecreasePercent)
%% Find steady range of input data
% Author: Xiang Liu@ASIPP
% Last Modified: 2014-08-07
% E-mail: jent.le@hotmail.com
% Version : 1.0
if nargin == 1
    dbStartPercent = 0.85;
    dbIncreasment = 0.01;
    dbDecreasePercent = 0.9;
else
    dbDecreasePercent = 1 - dbDecreasePercent;
end
dbMax = max(dbData);
iIndex = find(dbData >= dbMax*dbStartPercent);
iLen = length(iIndex);
for dbThres = dbStartPercent+dbIncreasment:dbIncreasment:1
    TempIndex = find(dbData >= dbMax*dbThres);
    iTempLen = length(TempIndex);
    if iTempLen > iLen*dbDecreasePercent
        iIndex = TempIndex;
        iLen = iTempLen;
    else
        break
    end
end
iRange = [min(iIndex) max(iIndex)];
end
