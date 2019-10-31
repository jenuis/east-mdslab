function q95 = proc_q95(shotno, time_range, efit_tree)
if nargin < 2
    time_range = [];
end
if nargin < 3
    efit_tree = 'efit_east';
end
q95 = signal_proc(shotno, efit_tree, 'q95', time_range);
