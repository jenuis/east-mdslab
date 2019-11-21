function pow_info = aux_stat(aux_heat, time_range)
%% old for 2014 and after
% pow_info = aux_stat_2014(aux_heat, time_range);
% return
%% heat type
HeatType = {'ecrh', 'icrf', 'lhw', 'nbi'};
LeastPow = 100; %[kW]
%% check arguments
time_range = sort(time_range([1 end]));
%% initilize outputs
for i=1:length(HeatType)
    pow_info.(HeatType{i}) = 0;
end
%% check aux_heat
if length(fieldnames(aux_heat)) == 1 && fieldexist(aux_heat, 'shotno')
    return
end
%% sum all time slices
time = time_range(1);
% total_slice = 0;
while(time<=time_range(2))
    heat_pow = aux_extract(aux_heat, time);
    heat_pow = powsign(heat_pow);
    heat_pow = powmerge(heat_pow);
    
    fp_names = fieldnames(heat_pow);
    tmp_heattype = HeatType;
    for i=1:length(fp_names)
        fpname = fp_names{i};
        for j=1:length(tmp_heattype)
            tmp_heatname = tmp_heattype{j};
            if strcmp(fpname(1:2), tmp_heatname(1:2))
%                 tmp_heatval = pow_info.(tmp_heatname);
%                 tmp_heatval = tmp_heatval + heat_pow.(fpname);
%                 pow_info.(tmp_heatname) = tmp_heatval;
                pow_info.(tmp_heatname)(end+1) = heat_pow.(fpname);
                break
            end
        end
        tmp_heattype(j) = [];
    end
    
    time = time+0.005;
%     total_slice = total_slice + 1;
end
%% cal mean
for i=1:length(HeatType)
%     pow_info.(HeatType{i}) = pow_info.(HeatType{i})/total_slice;

    tmp_val = pow_info.(HeatType{i});
    if strcmpi(HeatType{i}, 'nbi')
        tmp_val = tmp_val(tmp_val > 500);
    else
        tmp_val = tmp_val(tmp_val > LeastPow);
    end
    
%     tmp_val_m = max(tmp_val)*0.8;

%     tmp_val_m = median(tmp_val);
%     tmp_val = tmp_val(tmp_val>=tmp_val_m);
    
    tmp_val = mean(tmp_val, 'omitnan');
    if isnan(tmp_val)
        tmp_val = 0;
    end
    pow_info.(HeatType{i}) = tmp_val;
end


function heat_pow = powsign(heat_pow)
%% now only apply to lhw
if ~fieldexist(heat_pow, 'lhw')
    return
end
%% call routinues accordding ly
if fieldexist(heat_pow, {'lhw', 'plhi1'}) ||...
        fieldexist(heat_pow, {'lhw', 'plhi2'})
    RefLHW = {'plhr1', 'plhr2'};
elseif fieldexist(heat_pow, {'lhw', 'plhi'})
    RefLHW = {'plhr'};
else
    return
end
lhw = heat_pow.lhw;
for i=1:length(RefLHW)
    if fieldexist(lhw, RefLHW{i})
        lhw.(RefLHW{i}) = -lhw.(RefLHW{i});
    end
end
heat_pow.lhw = lhw;

function heat_pow = powmerge(heat_pow)
fp_names = fieldnames(heat_pow);
for i=1:length(fp_names)
    fpname = fp_names{i};
    sp_names = fieldnames(heat_pow.(fpname));
    tmp_val = 0;
    for j=1:length(sp_names)
        spname = sp_names{j};
        tmp_val = tmp_val + heat_pow.(fpname).(spname);
    end
%     tmp_val = tmp_val/length(sp_names);
    heat_pow.(fpname) = tmp_val;
end

function pow_info = aux_stat_2014(aux_heat, time_range)
time_range = sort(time_range([1 end]));
%% initialize heat_pow
heat_pow.pecrh1i = [];
heat_pow.pecrh3i = [];
heat_pow.picrfii = [];
heat_pow.picrfbi = [];
heat_pow.plh1 = [];
heat_pow.plh2 = [];
heat_pow.nbi1 = [];
heat_pow.nbi2 = [];
%% cal all time slices
time = time_range(1);
while(time<=time_range(2))
    tmp = aux_extract(aux_heat, time);
    heat_pow.pecrh1i(end+1) = tmp.pecrh1i;
    heat_pow.pecrh3i(end+1) = tmp.pecrh3i;
    heat_pow.picrfii(end+1) = tmp.picrfii;
    heat_pow.picrfbi(end+1) = tmp.picrfbi;
    heat_pow.nbi1(end+1) = tmp.nbi1;
    heat_pow.nbi2(end+1) = tmp.nbi2;
    % deduct reflection power
    heat_pow.plh1(end+1) = tmp.plhi1-tmp.plhr1;
    heat_pow.plh2(end+1) = tmp.plhi2-tmp.plhr2;
    
    time = time+0.005;
end
%% calculate top mean
field_names = fieldnames(heat_pow);
for i=1:length(field_names)
    field_name = field_names{i};
    data = heat_pow.(field_name);
    max_val = max(data);
    inds = data>=max_val*0.8;
    if ~isempty(inds)
        heat_pow.(field_name) = mean(data(inds));
    else
        heat_pow.(field_name) = 0;
    end
end
%% set outputs
pow_info.ecrh = heat_pow.pecrh1i + heat_pow.pecrh3i;
pow_info.icrf = heat_pow.picrfii + heat_pow.picrfbi;
pow_info.lhw = heat_pow.plh1 + heat_pow.plh2;
pow_info.nbi = heat_pow.nbi1 + heat_pow.nbi2;