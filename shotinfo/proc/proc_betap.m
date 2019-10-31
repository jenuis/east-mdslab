function betap = proc_betap(shotno, time_range, efit_tree)
if nargin < 2
    time_range = [];
end
if nargin < 3
    efit_tree = 'efit_east';
end
betap = signal_proc(shotno, efit_tree, 'betap', time_range);