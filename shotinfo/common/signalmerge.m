function signal_merged = signalmerge(signal_parent)
signal_merged.status = 0;
sig_names = fieldnames(signal_parent);
for i=1:length(sig_names)
    sig_name = sig_names{i};
    if ~fieldexist(signal_parent.(sig_name), 'time') || ~fieldexist(signal_parent.(sig_name), 'data')
        continue
    end
    if i == 1
        signal_merged.time = signal_parent.(sig_name).time;
        signal_merged.data = signal_parent.(sig_name).data;
        signal_merged.status = 1;
    else
        signal_merged.data = signal_merged.data + signal_parent.(sig_name).data;
    end
end