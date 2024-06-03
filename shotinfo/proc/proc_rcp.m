function rcp = proc_rcp(shotno, time_range)
if nargin < 2
    time_range = [];
end
rcp = signal_proc(shotno, 'east_1', 'rcp_j', time_range);
if rcp.status
    return
end
rcp = signal_proc(shotno, 'east_1', 'hq01', time_range);