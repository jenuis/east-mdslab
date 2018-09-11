function tritop = proc_tritop(shotno, time_range)
if nargin == 1
    time_range = [];
end
tritop = signal_proc(shotno, 'efit_east', 'tritop', time_range);
