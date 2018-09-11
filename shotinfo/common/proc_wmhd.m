function wmhd = proc_wmhd(shotno, time_range)
if nargin == 1
    time_range = [];
end
wmhd = proc_sig(shotno, 'efit_east', '\wmhd', time_range);