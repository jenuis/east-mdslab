function sig = signal_flatten(sig)
time_size = sort(size(sig.time));
data_size = sort(size(sig.data));
if isequal(time_size, data_size) && min(time_size) > 1
    sig.time = reshape(sig.time, 1, prod(time_size));
    sig.data = reshape(sig.data, 1, prod(time_size));
end