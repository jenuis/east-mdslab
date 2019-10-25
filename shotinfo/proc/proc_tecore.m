function te = proc_tecore(shotno, time_range, instr_type)
%% check arguments
if nargin == 1
    time_range = [];
    instr_type = 'ts';
elseif nargin == 2
    instr_type = 'ts';
end
%% ECE
if ~haselement({'hrs','mi','ts'},instr_type)
    error('Instrument Type wrong, should be "ts", "hrs" or "mi"!')
end
if haselement({'hrs','mi'},instr_type)
    signal_name = ['te0_' instr_type];
    te = signal_proc(shotno, 'Analysis', signal_name, time_range);
    return
end
%% TS
ts = signal(shotno, 'analysis', 'te_coreTS', 'rn');
te.status = 0;
if isempty(ts.time)
    return
end
te.time = ts.time;
ts_r = 1.9;
ts_z = signal(shotno, 'analysis', 'z_coreTS', 'rn');ts_z = ts_z.data;
sp=shotpara(shotno);sp.readmaxis;
zmaxis = sp.maxisloc.sigunbund('zmaxis');

te.data = [];
for i=1:length(te.time)
    t = te.time(i);
    efit_t_ind = findvalue(sp.maxisloc.time, t);
    curr_zmaxis = zmaxis(efit_t_ind);
    te_profile = ts.data(:, i);
    if length(ts_z) == length(te_profile)
        te.data(end+1) = pchip(ts_z, te_profile, curr_zmaxis);
    else
        warning('length(TS_Z) ~= length(TS_profile)');
        te.time = [];
        te.data = [];
        return
    end
end
if length(te.data) == length(te.time)
    te.status = 1;
end
