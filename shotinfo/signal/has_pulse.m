function [status, pulse_time] = has_pulse(sig, varargin)
%% check arguments
Args.BndRatio = 0.02;
Args.BgRatio = 0.08;
Args.BgTimeMax = 0;
Args.DownSamplePoint = 10;
Args.DownSampleMethod = 'median';
Args.PulseLenMin = 0.2;
Args.PulseLenMax = inf;
Args.PulseLenMinRatio = 0;
Args.PulseLenMaxRatio = 1.0;
Args.PulseAmpMin = 0;
Args.PulseAmpMax = inf;
Args.PulseAmpMinRatio = 3;
Args.PulseAmpMaxRatio = inf;
Args.Ip = [];
Args.Plot = 0;
Args = parseArgs(varargin, Args, {'Plot'});
%% init outputs
status = 0;
pulse_time = [];
%% downsample signal
sig.time = downsamplebymean(sig.time, Args.DownSamplePoint, Args.DownSampleMethod);
sig.data = downsamplebymean(sig.data, Args.DownSamplePoint, Args.DownSampleMethod);
%% slice signal and get background
bg = sig.data(1:floor(length(sig.data)*Args.BgRatio));
inds = sig.time <= Args.BgTimeMax;
if ~isempty(inds) && sum(inds) > length(bg)
    bg = sig.data(inds);
end
if isempty(Args.Ip)
    inds = sig.time > 0;
    sig.time = sig.time(inds);
    sig.data = sig.data(inds);
else
    sig = signal_slice(sig, Args.Ip.flat_time);
end
if Args.Plot
    figure(gcf)
    plot(sig.time, sig.data, 'k-');
    hold on
    plot(sig.time(1:length(bg)), bg, 'r-')
    xlabel('Time [s]')
end
%% check pulse apmlitute
sig_pp = diff(rangebystat(sig.data, Args.BndRatio));
bg_pp = diff(rangebystat(bg, Args.BndRatio));
if Args.Plot
    h = hline([0 1]*sig_pp+mean(bg)-bg_pp/2); set(h, 'linewidth', 1.5, 'color', 'k');
    h = hline([-.5 .5]*bg_pp+mean(bg)); set(h, 'linewidth', 1.5, 'color', 'r');
end
if sig_pp < Args.PulseAmpMin ...
        || sig_pp > Args.PulseAmpMax ...
        || sig_pp <= bg_pp ...
        || sig_pp/bg_pp < Args.PulseAmpMinRatio ...
        || sig_pp/bg_pp > Args.PulseAmpMaxRatio
    return
end
%% check pulse length
dt = mean(diff(sig.time));

bg_mean = mean(bg);
sig_mean = mean(sig.data( sig.data<=bg_mean+bg_pp/2 & sig.data>=bg_mean-bg_pp/2 ));
inds = sig.data > sig_mean + bg_pp;

inds_sum = sum(inds);
status = inds_sum/length(sig.time) >= Args.PulseLenMinRatio;
status = status && inds_sum/length(sig.time) <= Args.PulseLenMaxRatio;

plulse_len = inds_sum*dt;
status = status && plulse_len >= Args.PulseLenMin;
status = status && plulse_len <= Args.PulseLenMax;

if Args.Plot
    textbp({num2str(plulse_len, 'pulse len: %.2fs'),...
        num2str(sig.time(end)-sig.time(1), 'total len: %.2fs'),...
        num2str(status, 'status:%i')},...
        'fontsize', 20,...
        'color','b');
end
if ~status
    return
end

pulse_time =sig.time(inds);
time_range = rangebystat(pulse_time, 0.1);
pulse_time = pulse_time(pulse_time >= min(time_range) & pulse_time <= max(time_range));

