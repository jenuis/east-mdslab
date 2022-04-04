%% Calculate the mean value of a plasmapara struct
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
function shot_para = plasmapara_mean(shot_para, time_range)
%% heat type
LeastPow = 100/1000; %[MW]
%% main
f_names = {  
    'ip'
    'ne'
    'bp'
    'q95'
    'delta'
    'kappa'
    'tritop'
    'tribot'
    'wmhd'
    'R'
    'a'
    'vloop'
    'prad'};
p_names = {
    'lhw'
    'icrf'
    'ech'
    'nbi'};

if nargin == 1
    time_range = shot_para.flat_time;
end


time_range_ind = timerngind(shot_para.time, time_range);
tinds = min(time_range_ind):max(time_range_ind);
field_names = fieldnames(shot_para);
for i=1:length(field_names)
    if haselement(f_names, field_names{i}) || haselement(p_names, field_names{i}) ...
        || strcmp(field_names{i}, 'time')
        shot_para.(field_names{i}) = shot_para.(field_names{i})(tinds);
    end
end

for i=1:length(f_names)
    fname = f_names{i};
    if fieldexist(shot_para, fname)
        shot_para.(fname) = mean(shot_para.(fname),'omitnan');
    else
        shot_para.(fname) = nan;
    end
end

for i=1:length(p_names)
    pname = p_names{i};
    if fieldexist(shot_para, pname)
        tmp_val = shot_para.(pname);
        tmp_val = tmp_val(tmp_val > LeastPow);
    else
        tmp_val = 0;
    end
    
    tmp_val = mean(tmp_val, 'omitnan');
    if isnan(tmp_val)
        tmp_val = 0;
    end
    shot_para.(pname) = tmp_val;
end
