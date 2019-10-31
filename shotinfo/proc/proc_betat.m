function betat = proc_betat(shotno, time_range, efit_tree)
if nargin < 2
    time_range = [];
end
if nargin < 3
    efit_tree = 'efit_east';
end
betat = signal_proc(shotno, efit_tree, 'betat', time_range);