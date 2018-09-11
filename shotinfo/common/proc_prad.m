function prad = proc_prad(shotno, time_range)
if nargin == 1
    time_range = [];
end
prad = signal_proc(shotno, 'Analysis', 'PradTot_axuv', time_range);
if prad.status
    prad.data = prad.data*1e-3; % [MW]
    prad.mean = prad.mean*1e-3;
    prad.std = prad.std*1e-3;
end