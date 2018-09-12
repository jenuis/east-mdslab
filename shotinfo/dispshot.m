function dispshot(shotlist)
%% constants
heat_type = {'lhw', 'icrf', 'nbi', 'ech'};
%% check arguments
if nargin == 0
    shotlist = mdscurrshot;
end
%% gen disp string
disp_str = {};
for i=1:length(shotlist)
    shotno = shotlist(i);
    
    ip = proc_ip(shotno);
    if ~ip.status
        continue
    end 
    time_range = ip.flat_time;
    
    times = time_range(1):0.1:time_range(end);
    pp = plasmapara(shotno, times);
    shot_stat = plasmapara_mean(pp);
    
    tmp_str = {sprintf('%05i ',shotno)};
    tmp_str{end+1} = sprintf('It:%05i ',int32(shot_stat.it));
    tmp_str{end+1} = sprintf('Ip:%03.0f ',shot_stat.ip);
    tmp_str{end+1} = sprintf('pulse:%03.1f ',diff(shot_stat.flat_time));
    tmp_str{end+1} = sprintf('ne:%02.1f ',shot_stat.ne);
    
    for j=1:length(heat_type)
        if shot_stat.(heat_type{j})
            tmp_str{end+1} = sprintf([heat_type{j} ':%01.2f '],shot_stat.lhw/1000);
        else
            tmp_str{end+1} = '          ';
        end
    end
    
    disp_str{end+1} = strjoin(tmp_str,'');
end
%% disp
clc
for i=1:length(disp_str)
    disp(disp_str{i})
    disp('------------------------------------------------------------------')
end
