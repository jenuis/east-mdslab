function ne = proc_ne_edge(shotno, time_range)

if nargin == 1
    time_range = [];
end

ne.status = 0;
ne.mean = nan;

pnt1 = signal_read(shotno, 'east_1', 'point_n1', time_range);
pnt11 = signal_read(shotno, 'east_1', '\point_n11', time_range);

pnt.status  = 0;
if pnt1.status && pnt11.status
    pnt.time = pnt1.time;
    pnt.data = (pnt1.data + pnt11.data)/2;
elseif pnt1.status
    pnt = pnt1;
elseif pnt11.status
    pnt = pnt11;
else
    return
end
pnt.mean = median(pnt.data);
if pnt.mean > 0.2
    pnt.status = 1;
end
if pnt.status
    ne = pnt;
end
