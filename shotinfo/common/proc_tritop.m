function tritop = proc_tritop(shotno, time_range)
if nargin == 1
    time_range = [];
end
tritop = proc_sig(shotno, 'efit_east', '\tritop', time_range);
