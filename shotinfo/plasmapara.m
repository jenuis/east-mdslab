function shot_para = plasmapara(shotno, times, varargin)
%% check ip
ip = proc_ip(shotno);
if ~ip.status
    shot_para = [];
    warning('shot is bad!')
    return
end
flat_time = ip.flat_time;
default_time = flat_time(1):.05:flat_time(2);
%% check arguments
if nargin == 0
    m = mds;shotno = m.mdscurrentshot;
    times = default_time;
elseif nargin == 1
    times = default_time;
else
    times = sort(times);
%     time_range = mergeintervals(ip.flat_time, times([1 end]));
%     [~, times] = timerngind(times, time_range);
end
time_range = times([1 end]);
dt = median(diff(times));

Args.NeType = 'auto';
Args = parseArgs(varargin, Args);

Args.NeType = lower(Args.NeType);  
assert(haselement({'auto', 'hcn', 'point'}, Args.NeType), '"NeType" not recognized!')
%% initialize outputs
shot_para.shotno = shotno;
shot_para.flat_time = flat_time;
shot_para.it = nan;
shot_para.time = times;
shot_para.ip = [];
shot_para.ne = [];
shot_para.lhw = [];
shot_para.icrf = [];
shot_para.ech = [];
shot_para.nbi = [];

shot_para.bt = nan;
shot_para.bp = [];
shot_para.q95 = [];
shot_para.delta = [];
shot_para.kappa = [];
shot_para.tritop = [];
shot_para.tribot = [];
shot_para.delta = [];
shot_para.wmhd = [];
shot_para.R = [];
shot_para.a = [];

shot_para.vloop = [];
shot_para.prad = [];
%% time independent
it = proc_it(shotno);
if ~it.status
    it.mean = nan;
end
shot_para.it = round(it.mean);
sp = shotpara(shotno);
sp.it.mean = shot_para.it;
sp.readmaxis;
sp.calbt;
shot_para.bt = sp.bt;
%% time dependent
if strcmpi(Args.NeType, 'auto')
    Args.NeType = 'all';
end
ne = proc_ne(shotno, time_range, Args.NeType);
aux_heat = aux_read(shotno);

q95 = proc_q95(shotno, time_range);
kappa = proc_kappa(shotno, time_range);
tritop = proc_tritop(shotno, time_range);
tribot = proc_tribot(shotno, time_range);
wmhd = proc_wmhd(shotno, time_range);
vloop = proc_vp(shotno, time_range);
prad = proc_prad(shotno, time_range);

efit_info = efit_map(shotno,[],1, time_range, 1);

if isempty(efit_info)
    bp.status = 0;
    R.status = 0;
    a.status = 0;
else
    bp.time = efit_info.time;
    bp.data = efit_info.lcfs_mid_bp;
    bp.status = 1;

    R.time = efit_info.time;
    R.data = efit_info.maxis_r;
    R.status = 1;

    a.time = efit_info.time;
    a.data = efit_info.a;
    a.status = 1;
end

for i=1:length(times)
    t_rng = [-.5 .5]*dt + times(i);
    %% ip
    shot_para.ip(end+1) = getsigval(ip, t_rng);
    %% ne
    if isempty(ne.meas)
        ne_val = nan;
    else
        ne_val = getsigval(ne.(ne.meas), t_rng);
    end
    shot_para.ne(end+1) = ne_val;
    %% power
    pow_info = aux_stat(aux_heat, t_rng);
    if pow_info.ecrh
        shot_para.ech(end+1) = pow_info.ecrh/1000;
    else
        shot_para.ech(end+1) = 0;
    end
    if pow_info.icrf
        shot_para.icrf(end+1) = pow_info.icrf/1000;
    else
        shot_para.icrf(end+1) = 0;
    end
    if pow_info.lhw
        shot_para.lhw(end+1) = pow_info.lhw/1000;
    else
        shot_para.lhw(end+1) = 0;
    end
    if pow_info.nbi
        shot_para.nbi(end+1) = pow_info.nbi/1000;
    else
        shot_para.nbi(end+1) = 0;
    end
    %% efit 
    shot_para.q95(end+1) = getsigval(q95, t_rng);
    shot_para.kappa(end+1) = getsigval(kappa, t_rng);
    shot_para.tritop(end+1) = getsigval(tritop, t_rng);
    shot_para.tribot(end+1) = getsigval(tribot, t_rng);
    shot_para.delta(end+1) = (shot_para.tritop(end) + shot_para.tribot(end))/2;
    shot_para.wmhd(end+1) = getsigval(wmhd, t_rng);
    shot_para.bp(end+1) = getsigval(bp, t_rng);
    shot_para.R(end+1) = getsigval(R, t_rng);
    shot_para.a(end+1) = getsigval(a, t_rng);
    shot_para.vloop(end+1) = getsigval(vloop, t_rng);
    shot_para.prad(end+1) = getsigval(prad, t_rng);
end



function val = getsigval(sig, t_rng)
val = nan;
if ~sig.status
    return
end
try
    val = signal_mean(sig, t_rng);
catch
end
