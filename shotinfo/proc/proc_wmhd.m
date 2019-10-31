function wmhd = proc_wmhd(shotno, time_range, efit_tree)
if nargin < 2
    time_range = [];
end
if nargin < 3
    efit_tree = 'efit_east';
end
wmhd = signal_proc(shotno, efit_tree, 'wmhd', time_range);