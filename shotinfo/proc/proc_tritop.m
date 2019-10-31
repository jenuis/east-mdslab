function tritop = proc_tritop(shotno, time_range, efit_tree)
if nargin < 2
    time_range = [];
end
if nargin < 3
    efit_tree = 'efit_east';
end
tritop = signal_proc(shotno, efit_tree, 'tritop', time_range);
