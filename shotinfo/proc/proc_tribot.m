function tribot = proc_tribot(shotno, time_range)
if nargin == 1
    time_range = [];
end
tribot = signal_proc(shotno, 'efit_east', 'tribot', time_range);