%% Find steady range of input data
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Author: Xiang Liu@ASIPP
% Last Modified: 2014-08-07
function flat_ind_rng = flattop(signal_data, thres_init, thres_increas_step, stop_criteria)
%% By populating the number of data that larger than a certain threshold to 
% extract information of the flat-top region of the input signal.
% 
% output:
%     flat_ind_rng: the indices of the start and end of the flat-top
%         region.
% input:
%     singal_data: signal data, for instance, the plasma current.
%     thres_init: the ratio between initial value to the peak value.
%         Default: 0.85.
%     thres_increas_step: the increasing step of the threshold. Default:
%         0.01.
%     stop_criteria: the stop criteria, where the ratio between the next- 
%         step population and the current-step popluation is smaller than
%         this value. Default: 0.9.
%% check arguments
if nargin == 1
    thres_init = 0.85;
    thres_increas_step = 0.01;
    stop_criteria = 0.9;
elseif nargin == 2
    thres_increas_step = 0.01;
    stop_criteria = 0.9;
elseif nargin == 3
    stop_criteria = 0.9;
end
%% main
data_max = max(signal_data); % max value of input signal data
inds = find(signal_data >= data_max*thres_init); % indices that larger than the initial value
population = length(inds); % the total number of values that larger than the initial value
for thres = thres_init+thres_increas_step:thres_increas_step:1 % increase threshold
    inds_next = find(signal_data >= data_max*thres); % next step indices
    popluation_next = length(inds_next); % population of the next step indices
    if popluation_next > population*stop_criteria % check stop criteria
        inds = inds_next;
        population = popluation_next;
    else
        break % stop criteria satisfied
    end
end
flat_ind_rng = [min(inds) max(inds)]; % assign output
