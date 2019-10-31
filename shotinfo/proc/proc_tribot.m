function tribot = proc_tribot(shotno, time_range, efit_tree)
if nargin < 2
    time_range = [];
end
if nargin < 3
    efit_tree = 'efit_east';
end
tribot = signal_proc(shotno, efit_tree, 'tribot', time_range);
