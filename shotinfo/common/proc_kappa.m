function kappa = proc_kappa(shotno, time_range)
if nargin == 1
    time_range = [];
end
kappa = proc_sig(shotno, 'efit_east', '\kappa', time_range);