%% Method for checking if the signal has an pulse or flat top
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
function [res, flat_ind] = haspulse(data)
flat_ind = flattop(data);
if isempty(flat_ind)
    res = 0;
    return
end
flat_data = data(flat_ind(1):flat_ind(2));
back_data = data;
back_data(flat_ind(1):flat_ind(2)) = [];
res = abs(mean(flat_data)/mean(back_data)) > 1.5;