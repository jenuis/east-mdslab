function betap = proc_betap(shotno, time_range)
if nargin == 1
    time_range = [];
end
betap = signal_proc(shotno, 'efit_east', 'betap', time_range);