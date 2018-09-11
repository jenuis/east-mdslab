function ne = proc_ne(shotno, time_range, ne_type)
if nargin == 2
    ne_type = 'all';
end
if haselement({'all','hcn'}, ne_type)
    hcn = mdsreadsignal(shotno, 'pcs_east', '\dfsdev', time_range);
    hcn = signalcheck(hcn);
    ne.status = 0;
    if hcn.status
        hcn.mean = mean(hcn.data);
        if 0.8 < hcn.mean && hcn.mean <10
            ne.status = 1;
            ne.hcn = hcn;
        end
    end
end
if haselement({'all','point'}, ne_type)
    point = mdsreadsignal(shotno, 'east_1', '\point_n6', time_range);
    point = signalcheck(point);
    if point.status
        point.mean = mean(point.data);
        if 0.8 < point.mean && point.mean < 10
            ne.status = 1;
            ne.point = point;
        end    
    end
end