function ip = proc_ip(shotno, least_flat_time, least_ip_value)
%% check arguments
if nargin == 1
    least_flat_time = 2;
    least_ip_value = 100e3;
end
%% check ip
ip = signal_read(shotno, 'pcs_east', 'pcrl01');
if ~ip.status
    return
end
[res, flat_time_ind] = haspulse(ip.data);
if ~res
    ip.status = 0;
    return
end
flat_time = ip.time(flat_time_ind);
flat_mean = mean(ip.data(flat_time_ind(1):flat_time_ind(2)));
if diff(flat_time) < least_flat_time || flat_time(1) < 0.7 || flat_mean < least_ip_value || max(ip.data(1:1000)) > least_ip_value/2
    ip.status = 0;
    return
end
ip.status = 1;
ip.flat_time = flat_time;
%% slice data greater than 0
start_ind = findtime(ip.time, -0.5);
ip.time = ip.time(start_ind:end);
ip.data = ip.data(start_ind:end);
%% convert units and cal mean
ip.data = ip.data*1e-3;
ip.mean = flat_mean*1e-3;
