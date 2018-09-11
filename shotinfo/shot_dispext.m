function shot_stat = dispshot_ext(shotlist, time_range_list)
if nargin == 0
    shot_stat = dispshot;
    shotlist = shot_stat.shotno{1};
    time_range_list = [shot_stat.pulse{1}];
else
    shot_stat = dispshot(shotlist, time_range_list);
end

if size(time_range_list, 1) == 2
    time_range_list = time_range_list';
end

if size(time_range_list, 1) == 1 && length(shotlist) > 1
    tmp = time_range_list;
    for i=2:length(shotlist)
        time_range_list = [time_range_list; tmp];
    end
end

% time_range = sort(time_range([1 end]));

shot_stat.bt = [];
shot_stat.bp = [];
shot_stat.q95 = [];
shot_stat.delta = [];
shot_stat.kappa = [];
shot_stat.tritop = [];
shot_stat.tribot = [];
shot_stat.delta = [];
shot_stat.wmhd = [];

for i=1:length(shotlist)
    shotno = shotlist(i);
    time_range = sort(time_range_list(i,:));
    sp = shotpara(shotno);
    sp.it.mean = shot_stat.it;
    sp.readmaxis;
    sp.calbt;
    shot_stat.bt = sp.bt;
    bp = proc_bp(shotno, time_range);
    if fieldexist(bp, 'mean')
        shot_stat.bp(i) = bp.mean;
    else
        shot_stat.bp(i) = nan;
    end
    q95 = proc_q95(shotno, time_range);
    if q95.status
        shot_stat.q95(i) = q95.mean;
    else
        shot_stat.q95(i) = nan;
    end
    kappa = proc_kappa(shotno, time_range);
    if kappa.status
        shot_stat.kappa(i) = kappa.mean;
    else
        shot_stat.kappa(i) = nan;
    end
    tritop = proc_tritop(shotno, time_range);
    if tritop.status
        shot_stat.tritop(i) = tritop.mean;
    else
        shot_stat.tritop(i) = nan;
    end
    tribot = proc_tribot(shotno, time_range);
    if tribot.status
        shot_stat.tribot(i) = tribot.mean;
    else
        shot_stat.tribot(i) = nan;
    end
    shot_stat.delta(i) = (shot_stat.tritop(i) + shot_stat.tribot(i))/2;
    wmhd = proc_wmhd(shotno, time_range);
    if wmhd.status
        shot_stat.wmhd(i) = wmhd.mean;
    else
        shot_stat.wmhd(i) = nan;
    end
end