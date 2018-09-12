function wmhd = proc_wmhd(shotno, time_range)
if nargin == 1
    time_range = [];
end
wmhd = signal_proc(shotno, 'efit_east', 'wmhd', time_range);