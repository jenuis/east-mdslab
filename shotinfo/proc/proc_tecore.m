function te = proc_tecore(shotno, time_range)
if nargin == 1
    time_range = [];
end
mi = profile(shotno, 'mi');
mi.loadbycal(time_range)