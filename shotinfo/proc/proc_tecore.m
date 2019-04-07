function te = proc_tecore(shotno, time_range, ece_type)
if nargin == 1
    time_range = [];
    ece_type = 'hrs';
elseif nargin == 2
    ece_type = 'hrs';
end
if ~haselement({'hrs','mi'},ece_type)
    error('ECE Type wrong, should be "hrs" or "mi"!')
end
signal_name = ['te0_' ece_type];
te = signal_proc(shotno, 'Analysis', signal_name, time_range);