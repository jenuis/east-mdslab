function kappa = proc_kappa(shotno, time_range, efit_tree)
if nargin < 2
    time_range = [];
end
if nargin < 3
    efit_tree = 'efit_east';
end
kappa = signal_proc(shotno, efit_tree, 'kappa', time_range);