%% Method for get data range by hist instead of [min, max]
% -------------------------------------------------------------------------
% Copyright 2022 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
function rng = histrange(data, binno, edge_omit_ratio)
if nargin < 3
    edge_omit_ratio = 0.01;
end

if nargin < 2
    binno = 80;
end

[N, X] = hist(data, binno);

omit_no_thres = sum(N)*edge_omit_ratio;

flag = [0 0];
ind_rng = [nan nan];
for i=1:floor(length(N)/2)
    if sum(flag) == 2
        break
    end
    
    if flag(1) == 0 && sum(N(1:i))>= omit_no_thres
        ind_rng(1) = i;
        flag(1) = 1;
    end
    
    if  flag(2) == 0 && sum(N(end+1-i:end)) >= omit_no_thres
        ind_rng(2) = length(N)+1-i;
        flag(2) = 1;
    end
end

if sum(flag) < 2
    rng = X([2 end-1]);
    rng(logical(flag)) = X(ind_rng(logical(flag)));
    warning('Can not get the hist range with the input parameters, use [N(2) N(end-1)] instead!')
    return
end

rng = X(ind_rng);