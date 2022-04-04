%% Method for generating bit representations of auxilary heating types
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
function pow_bit = genpowbit(pow_info, order)
%% check arguments
if nargin < 2
    order = {'ecrh', 'icrf', 'lhw', 'nbi'};
end
if fieldexist(pow_info, 'ech') && ~fieldexist(pow_info, 'ecrh')
    pow_info.ecrh = pow_info.ech;
end
for i=1:length(order)
    if fieldexist(pow_info, order{i})
        len = length(pow_info.(order{i}));
        break
    end
end
for i=1:length(order)
    name = order{i};
    if ~fieldexist(pow_info, name)
        error(['Can not find pow_info.' name]);
    end
    if length(pow_info.(name)) ~= len
        error('different length for data in pow_info!')
    end
end
pow_bit = [];
%% recursive call
if length(pow_info.ecrh) > 1
    tmp = struct();
    for i=1:length(pow_info.ecrh)
        for j=1:length(order)
            name = order{j};
            tmp.(name) = pow_info.(name)(i); 
        end
        pow_bit(i) = genpowbit(tmp);
    end
    return
end
%% cal pow_bit
for i=1:length(order)
    pow_bit(i) =  pow_info.(order{i});
end
pow_bit = bit2dec(logical(pow_bit));
