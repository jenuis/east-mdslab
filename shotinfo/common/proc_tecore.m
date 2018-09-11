function te = proc_tecore(shotno, time_range)
if nargin == 1
    time_range = [];
end
% te = proc_sig(shotno, 'Analysis', '\te0_hrs', time_range);
mi = profile(shotno, 'mi');
mi.loadbycal(time_range)