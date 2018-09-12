function value = signal_mean(signal, time_range)
time_ind = timerngind(signal.time, time_range);
value = mean(signal.data(time_ind(1):time_ind(2)));