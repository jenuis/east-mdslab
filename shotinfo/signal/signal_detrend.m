function sig = signal_detrend(sig, detrend_time)
if nargin < 2
    dt = mean(diff(sig.time));
    detrend_time = dt*10;
end

ind_list = timeparts(sig.time, detrend_time);
for i=1:length(ind_list)
    ind = ind_list{i};
    tmp_data = sig.data(ind);
    tmp_data = tmp_data-median(tmp_data);
    sig.data(ind) = tmp_data;
end