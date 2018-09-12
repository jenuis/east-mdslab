function sig = signal_proc(shotno, tree_name, node_name, time_range)
%% init output
sig.status = 0;
sig.mean = nan;
sig.std = nan;
%% check arguments
if nargin == 3 || isempty(time_range)
    ip = proc_ip(shotno);
    if ~ip.status
        return
    end
    time_range = ip.flat_time;
end
%% process signal
sig = signal_read(shotno, tree_name, node_name, time_range);
if ~sig.status
    return
end
sig.mean = mean(sig.data, 'omitnan');
sig.std = std(sig.data, 'omitnan');