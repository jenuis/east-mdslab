function energy = proc_energy(shotno, time_range)
if nargin < 2
    time_range = [];
end
energy = signal_proc(shotno, 'energy_east', 'eng', time_range);