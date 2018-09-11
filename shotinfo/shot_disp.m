function shot_stat = dispshot(shotlist, time_range_list)
if nargin == 0
    shotlist = mdscurrshot;
else
    if nargin == 2 && size(time_range_list,1) == 2
        time_range_list = time_range_list';
    end
end

if size(time_range_list, 1) == 1 && length(shotlist) > 1
    tmp = time_range_list;
    for i=2:length(shotlist)
        time_range_list = [time_range_list; tmp];
    end
end

shot_stat.shotno=[];
shot_stat.ip=[];
shot_stat.it=[];
shot_stat.ne=[];
shot_stat.lhw=[];
shot_stat.icrf=[];
shot_stat.ech=[];
shot_stat.nbi=[];
shot_stat.pulse={};

shot_stat_str = {};
for i=1:length(shotlist)
    shotno = shotlist(i);
    ip = proc_ip(shotno);
    if ~ip.status
        continue
    end
    
    if nargin == 2
        time_range = sort(time_range_list(i,:));
    else
        time_range = ip.flat_time;
    end
    
    it = proc_it(shotno);
    if ~it.status
        it.mean = nan;
    end
    ne = proc_ne(shotno, time_range, 'hcn');
    if ~fieldexist(ne,{'hcn'}) || ~ne.hcn.status
        ne.hcn.mean = nan;
    end
    aux_heat = aux_read(shotno);
    pow_info = aux_stat(aux_heat, time_range);
    
    str={};
    str{end+1} = sprintf('%05i ',shotno);
    str{end+1} = sprintf('It:%05i ',int32(it.mean));
    str{end+1} = sprintf('Ip:%03.0f ',ip.mean);
    str{end+1} = sprintf('pulse:%03.1f ',diff(time_range));
    str{end+1} = sprintf('ne:%02.1f ',ne.hcn.mean);
    
    shot_stat.shotno(end+1) = shotno;
    shot_stat.it(end+1) = int32(it.mean);
    shot_stat.ip(end+1) = ip.mean;
    shot_stat.pulse{end+1} = time_range;
    shot_stat.ne(end+1) = ne.hcn.mean;
    
    if pow_info.lhw
        str{end+1} = sprintf('lhw:%01.2f ',pow_info.lhw/1000);
        shot_stat.lhw(end+1) = pow_info.lhw/1000;
    else
        str{end+1} = '         ';
        shot_stat.lhw(end+1) = 0;
    end
    if pow_info.icrf
        str{end+1} = sprintf('icrf:%01.2f ',pow_info.icrf/1000);
        shot_stat.icrf(end+1) = pow_info.icrf/1000;
    else
        str{end+1} = '          ';
        shot_stat.icrf(end+1) = 0;
    end
    if pow_info.nbi
        str{end+1} = sprintf('nbi:%01.2f ',pow_info.nbi/1000);
        shot_stat.nbi(end+1) = pow_info.nbi/1000;
    else
        str{end+1} = '         ';
        shot_stat.nbi(end+1) = 0;
    end
    if pow_info.ecrh
        str{end+1} = sprintf('ecrh:%01.2f ',pow_info.ecrh/1000);
        shot_stat.ech(end+1) = pow_info.ecrh/1000;
    else
        str{end+1} = '          ';
        shot_stat.ech(end+1) = 0;
    end
    shot_stat_str{end+1} = strjoin(str,'');
%     break
end
clc
for i=1:length(shot_stat_str)
    disp(shot_stat_str{i})
    disp('------------------------------------------------------------------')
end