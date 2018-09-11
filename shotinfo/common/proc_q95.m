function q95 = proc_q95(shotno, time_range)
if nargin == 1
    time_range = [];
end
q95 = proc_sig(shotno, 'efit_east', '\q95', time_range);
