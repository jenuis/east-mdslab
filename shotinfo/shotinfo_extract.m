function shot_stat = shotinfo_extract(shot_info, time_range)
shot_stat.time = mean(time_range);
%% proc ip
% shot_stat.ip = floor(mean(shot_info.ip.sigpartdata(time_range))/10)*10;
shot_stat.ip = mean(shot_info.ip.sigpartdata(time_range));
%% proc it
if isfield(shot_info, 'it')
    shot_stat.it = shot_info.it;
else
    shot_stat.it = nan;
end
%% proc ne
if isfield(shot_info, 'ne')
    shot_stat.ne = mean(shot_info.ne.sigpartdata(time_range));
else
    shot_stat.ne = nan;
end
%% aux
pow_info = aux_stat(shot_info.aux, time_range);
shot_stat.powbit = genpowbit(pow_info);
field_names = fieldnames(pow_info);
for i=1:length(field_names)
    field_name = field_names{i};
    shot_stat.(field_name) = pow_info.(field_name);
end
%% proc q95
if isfield(shot_info, 'q95')
    shot_stat.q95 = mean(shot_info.q95.sigpartdata(time_range));
else
    shot_stat.q95 = nan;
end
%% proc bp
if isfield(shot_stat, 'bp')
    shot_stat.bp = mean(shot_info.bp.sigpartdata(time_range));
else
    shot_stat.bp = nan;
end
%% proc kappa
if isfield(shot_stat, 'kappa')
    shot_stat.kappa = mean(shot_info.kappa.sigpartdata(time_range));
else
    shot_stat.kappa = nan;
end
%% proc tritop
if isfield(shot_stat, 'tritop')
    shot_stat.tritop = mean(shot_info.tritop.sigpartdata(time_range));
else
    shot_stat.tritop = nan;
end
%% proc tribot
if isfield(shot_stat, 'tribot')
    shot_stat.tribot = mean(shot_info.tribot.sigpartdata(time_range));
else
    shot_stat.tribot = nan;
end
