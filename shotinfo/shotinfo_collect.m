function shot_info = shotinfo_collect(shotno)
%% proc ip
ip = proc_ip(shotno);
if ~ip.status
    return
end
flat_time = ip.flat_time;
shot_info.ip = signal(shotno);
shot_info.ip.time = ip.time;
shot_info.ip.data = ip.data';
%% proc it
it = proc_it(shotno);
if ~it.status
    it.mean = nan;
end
shot_info.it = it.mean;
%% proc ne
ne = proc_ne(shotno, flat_time, 'hcn');
if fieldexist(ne,{'hcn'}) && ne.hcn.status
    shot_info.ne = signal(shotno);
    shot_info.ne.time = ne.hcn.time;
    shot_info.ne.data = ne.hcn.data';
end
%% aux
shot_info.aux = aux_read(shotno);
%% proc q95
q95 = proc_q95(shotno, flat_time);
if q95.status
    shot_info.q95 = signal(shotno);
    shot_info.q95.time = q95.time;
    shot_info.q95.data = q95.data';
end
%% proc bp
bp = proc_bp(shotno, flat_time);
if fieldexist(bp, 'mean')
    shot_info.bp = signal(shotno);
    shot_info.bp.time = bp.time;
    shot_info.bp.data = bp.data;
end
%% proc kappa
kappa = proc_kappa(shotno, flat_time);
if kappa.status
    shot_info.kappa = signal(shotno);
    shot_info.kappa.time = kappa.time;
    shot_info.kappa.data = kappa.data';
end
%% proc tritop
tritop = proc_tritop(shotno, flat_time);
if tritop.status
    shot_info.tritop =signal(shotno);
    shot_info.tritop.time = tritop.time;
    shot_info.tritop.data = tritop.data';
end
%% proc tribot
tribot = proc_tribot(shotno, flat_time);
if tribot.status
    shot_info.tribot = signal(shotno);
    shot_info.tribot.time = tribot.time;
    shot_info.tribot.data = tribot.data';
end
