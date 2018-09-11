function signal = signaldownsample(signal, avg_len)
if nargin == 1
    avg_len = 20;
end
if ~fieldexist(signal, 'time') || ~fieldexist(signal, 'data')
    return
end
signal.time = downsamplebymean(signal.time, avg_len);
signal.data = downsamplebymean(signal.data, avg_len);