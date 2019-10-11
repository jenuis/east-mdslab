function ne = proc_ne(shotno, time_range, ne_type)
if nargin == 2
    ne_type = 'all';
elseif nargin == 1
    time_range = [];
    ne_type = 'all';
end
ne.status = 0;
if haselement({'all','hcn'}, ne_type)
    hcn = signal_read(shotno, 'pcs_east', 'dfsdev', time_range);
    if hcn.status
        hcn.mean = mean(hcn.data);
        if 0.8 < hcn.mean && hcn.mean <10
            ne.status = 1;
            ne.hcn = hcn;
        end
    end
end
if haselement({'all','point'}, ne_type)
    point = signal_read(shotno, 'pcs_east', 'dfsdev2', time_range);
    if point.status
        point.mean = mean(point.data);
        if 0.8 < point.mean && point.mean < 10
            ne.status = 1;
            ne.point = point;
        end
    end
end

hcn_flag = fieldexist(ne, 'hcn');
pnt_flag = fieldexist(ne, 'point');

switch hcn_flag*2+pnt_flag
    case 3
        netar = signal_read(shotno,'pcs_east','dftden', time_range);
        if netar.status
            ne.tar = netar;
            ind_rng = flattop(netar.data);
            sum_hcn = 0;
            sum_pnt = 0;
            for i=ind_rng(1):ind_rng(2)
                sum_hcn = sum_hcn + (netar.data(i)-hcn.data(i))^2;
                sum_pnt = sum_pnt + (netar.data(i)-point.data(i))^2;
            end
            if sum_hcn > sum_pnt
                ne.meas = 'point';
            else
                ne.meas = 'hcn';
            end
        else
            error('can not get target density!')
        end
        figure
        plot(netar.time, netar.data)
        hold on
        plot(hcn.time, hcn.data)
        plot(point.time, point.data)
        plot(netar.time(ind_rng), netar.data(ind_rng), 'ro', 'markersize',10)
        legend('tar','hcn','point')
        title(ne.meas)
    case 2
        ne.meas = 'hcn';
    case 1
        ne.meas = 'point';
    otherwise
        ne.meas = '';
end
