function heat_pow = aux_extract(aux_heat, time_range)
%% old routine for 2014 after
% heat_pow = aux_extract_2014(aux_heat, time_range);
% return
%% config
least_power = 100;
if length(time_range) == 1
    time_range(2) = time_range;
end
%% initialize outputs
heat_pow = [];
%% extract power
fp_names = fieldnames(aux_heat);
for i=1:length(fp_names)
    fpname = fp_names{i};
    if ~isstruct(aux_heat.(fpname))
        continue
    end
    sp_names = fieldnames(aux_heat.(fpname));
    for j=1:length(sp_names)
        spname = sp_names{j};
        pow_sig = aux_heat.(fpname).(spname);
        pow_sig_slice = signalslice(pow_sig, time_range);
        pow_val = mean(pow_sig_slice.data);
        if pow_val < least_power
            pow_val = 0;
        end
        heat_pow.(fpname).(spname) = pow_val;
    end
end

function heat_pow = aux_extract_2014(aux_heat, time_range)
%% config
least_power = 100;
if length(time_range) == 1
    time_range = [time_range time_range];
end
%% initialize output
heat_pow.pecrh1i = 0;
heat_pow.picrfii = 0;
heat_pow.picrfbi = 0;
heat_pow.plhi1 = 0;
heat_pow.plhi2 = 0;
heat_pow.nbi1 = 0;
heat_pow.nbi2 = 0;

% reflection power
heat_pow.plhr1 = 0;
heat_pow.plhr2 = 0;
%% extract power
heat_type_names = fieldnames(aux_heat);
for i=1:length(heat_type_names)
    heat_type = heat_type_names{i};
    if ~isstruct(aux_heat.(heat_type))
        continue
    end
    pow_names = fieldnames(aux_heat.(heat_type));
    for j=1:length(pow_names)
        pow_name = pow_names{j};
        tmp = signalslice(aux_heat.(heat_type).(pow_name), time_range);
%         heat_pow.(pow_name) = signalextract(aux_heat.(heat_type).(pow_name), time_range);
        heat_pow.(pow_name) = mean(tmp.data);
    end
end
%% revise power
pow_names = fieldnames(heat_pow);
for i=1:length(pow_names)
    pow_name = pow_names{i};
    if heat_pow.(pow_name) < least_power
        heat_pow.(pow_name) = 0;
    end
end