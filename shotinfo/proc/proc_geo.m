function drsep = proc_geo(shotno, time_range)
if shotno <= 44326
    tree_name = 'efitrt_east';
%     error('Has problems for processing 2012 campain data!')
else
    tree_name = 'efit_east';
end
if nargin == 1
    time_range = [];
end
drsep = signal_read(shotno, tree_name, 'drsep', time_range);

if ~drsep.status
    return
end
ind = abs(drsep.data) > 0.06;
drsep.data(ind) = nan;
drsep.mean = mean(drsep.data,'omitnan')*1e3;