% function [ind_rng, new_time] = timerngind(time_array, time_range, dtmaxtimes)
function [ind_rng, new_time] = timerngind(time_array, time_range)
%% check arguments
% if nargin == 2
%     dtmaxtimes = 2.5;
% end
if isempty(time_range) || isempty(time_array)
    ind_rng = time_range;
    new_time = time_array;
    return
end
if  ~isnumeric(time_array) || ~isnumeric(time_range)...
        || length(time_range) > 2
    error('Invalid input arguments!');
end
if  length(time_range) == 1
    time_range(2) = time_range;
end
%% check time_array
time_diff = diff(time_array);
if isempty(time_diff)
    error('Time array length less than 2!')
end
if ~isempty(find(time_diff < 0, 1))
    error('Time array is not monotonically increasing!');
end
% dt = median(time_diff);
% dt_max = max(time_diff);
% if dt_max/dt > dtmaxtimes
%     error('time_array not even, has big gap!')
% end
% dt = dt_max;
%% mod time_range
time_range = sort(time_range);
% [~, ~, all_in_range] = inrange([time_array(1)-10*dt time_array(end)+10*dt], time_range);
% if ~all_in_range
%     error('"time_range" inputted is out of range of "time_array" by 10*dt!');
% end
new_range = mergeintervals(time_array([1 end]), time_range);
%% final process
ind_rng = findvalue(time_array, new_range);
if ~isempty(ind_rng)
    new_time = time_array(ind_rng(1):ind_rng(2));
else
    new_time = [];
end