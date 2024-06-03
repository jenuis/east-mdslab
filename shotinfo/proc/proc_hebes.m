function hebes = proc_hebes(shotno, time_range)
if nargin < 2
    time_range = [];
end
hebes = signal_proc(shotno, 'east_1', 'hec13', time_range);