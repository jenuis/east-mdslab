function vp = proc_vp(shotno, time_range)
if nargin ==1
    time_range = [];
end
vp = signal_proc(shotno, 'pcs_east', 'pcvloop', time_range);