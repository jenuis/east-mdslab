%% Method for geting segment of auxilary heating struct
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
function seg = aux_segment(aux, time_range, dt, merge_same_pow)
%% get time_range
if nargin == 1
    field_names = fieldnames(aux);
    first_pow = aux.(field_names{1});
    pow_names = fieldnames(first_pow);
    first_subpow = first_pow.(pow_names{1});
    time_range = first_subpow.time([1 end]);
    time_range(1) = max([time_range(1) 0]);
    dt = 0.01;
    merge_same_pow = 1;
elseif nargin == 2
    dt = 0.01;
    merge_same_pow = 1;
elseif nargin == 3
    merge_same_pow = 1;
end
%% get segments
time = time_range(1):dt:time_range(2);
seg{1,1} = time(1);
seg{2,1} = get_aux_state(aux, time(1), merge_same_pow);
for i = 2:(length(time)-1)
    t = time(i);
    aux_state_tmp = get_aux_state(aux, t, merge_same_pow);
    if ~isequal(aux_state_tmp, seg{2, end})
        seg{1, end+1} = t;
        seg{2, end} = aux_state_tmp;
    end
end
seg{1,end+1} = time(end);
seg{2,end} = get_aux_state(aux, time(end), merge_same_pow);


function aux_state = get_aux_state(aux, t, merge_same_pow)
heat_pow = aux_extract(aux, t);
pow_array = struct2array(heat_pow);
if length(pow_array) == 7 && merge_same_pow
    pow_array([2 4 6]) = pow_array([2 4 6]) + pow_array([3 5 7]);
    pow_array([3 5 7]) = [];
end
aux_state = logical(pow_array);
