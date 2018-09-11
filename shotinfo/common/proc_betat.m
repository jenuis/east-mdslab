function betat = proc_betat(shotno, time_range)
if nargin == 1
    time_range = [];
end
betat = signal_proc(shotno, 'efit_east', 'betat', time_range);