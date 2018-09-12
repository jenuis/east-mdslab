function shot_para = plasmapara_mean(shot_para)
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

for i=1:length(f_names)
    fname = f_names{i};
    shot_para.(fname) = mean(shot_para.(fname),'omitnan');
end

for i=1:length(p_names)
    pname = p_names{i};
    tmp_val = shot_para.(pname);
    tmp_val = tmp_val(tmp_val > LeastPow);
    
    tmp_val = mean(tmp_val, 'omitnan');
    if isnan(tmp_val)
        tmp_val = 0;
    end
    shot_para.(pname) = tmp_val;
end
