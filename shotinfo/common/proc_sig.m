function sig = proc_sig(shotno, tree_name, node_name, time_range)
if nargin == 3
    time_range = [];
end
sig = mdsreadsignal(shotno, tree_name, node_name, time_range);
sig = signalcheck(sig);

sig.mean = nan;
sig.std = nan;
if ~sig.status
    return
end
sig.mean = mean(sig.data);
sig.std = std(sig.data);