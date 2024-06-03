function [elm_ind_sig, elm_ind_da] = remove_elm(sigda, sig_time, plot_res, varargin)
%% [elm_ind_sig, elm_ind_da] = remove_elm(sigda, sig_time, plot_res)
% [elm_ind_sig, elm_ind_da] = remove_elm(sigda, sig_time)
% elm_ind_da = remove_elm(sigda)
%% check arguments
if nargin <= 2
    plot_res = 0;
end
if nargin <= 1
    sig_time = [];
end
%% constants control
Args.ThresFindPeak = exp(-1);
Args.ThresRemoveELM = 0.1;
Args.RemoveELMDelay = 0;
Args.RemoveELMPre = 0;
Args.ELMPeriodMin = 0.0005;

Args = parseArgs(varargin, Args);

thres_find_peak = Args.ThresFindPeak;
thres_rm_elm = Args.ThresRemoveELM;
time_rm_elm_delay = Args.RemoveELMDelay;
time_rm_elm_pre = Args.RemoveELMPre;
ELM_period_min = Args.ELMPeriodMin;
smooth_points = 35;
detrend_time = 0.01;
elm_find_time = 0.1;
%% copy sigda
sigda_cpy = sigda.copy;
sigda_dt = mean(diff(sigda.time));
%% smooth and detrend data
sigda.data = sgolayfilt(sigda.data,1,smooth_points);
sigda = signal_detrend(sigda, detrend_time);
%% find elm in sigda
cfg.elm_period_min_len =  round(ELM_period_min/sigda_dt);
cfg.thres_elm_low = thres_rm_elm;
cfg.smooth_points = smooth_points;
% cfg.elm_min_peak = mean(sigda.data(sigda.data>=max(sigda.data)*thres_find_peak))*thres_find_peak;
tmp_data = sort(sigda.data); sigda_large = tmp_data(round(0.999*length(tmp_data))); cfg.elm_min_peak = mean(sigda.data(sigda.data>=sigda_large*thres_find_peak))*thres_find_peak;

ind_delay = round(time_rm_elm_delay/sigda_dt);
ind_pre = round(time_rm_elm_pre/sigda_dt);

elm_peak_loc = [];
elm_ind_da = [];
ind_list = timeparts(sigda.time, elm_find_time);

for i=1:length(ind_list)
    ind = ind_list{i};
    tmp_data = sigda.data(ind);
    [a, b] = find_elm(tmp_data, cfg);
    
    for j=1:length(a)
        b = [b (-ind_pre:-1)+a(j)];
        b = [b (1:ind_delay)+a(j)];
        b = unique(b);
    end
    
    a = a + ind(1) -1;
    b = b + ind(1) -1;
    elm_peak_loc = [elm_peak_loc a];
    elm_ind_da = [elm_ind_da b];
end
%% plots
if plot_res
    x = sigda_cpy.time;
    y = sigda_cpy.data;
    x(elm_ind_da) = [];
    y(elm_ind_da) = [];
    sigda_cpy.sigplot;
    hold on
    plot(sigda_cpy.time(elm_peak_loc),sigda_cpy.data(elm_peak_loc),'ro')
    plot(x,y,'c.')
    hold off
end
%% find elm time in sig
elm_ind_sig = [];
if isempty(sig_time)
    return
end
sig_dt = median(diff(sig_time));
if isempty(sig_dt) || isnan(sig_dt)
    return
end
for i=1:length(elm_ind_da)
    curr_time = sigda_cpy.time(elm_ind_da(i));
    tmp_ind = findvaluecrit(sig_time, curr_time, sig_dt);
    if ~isnan(tmp_ind) && isempty(find(elm_ind_sig == tmp_ind, 1))
        elm_ind_sig(end+1) = tmp_ind;
    end
end


function [elm_peak_loc, elm_ind] = find_elm(data, cfg)
min_dist = cfg.elm_period_min_len;
min_peak = cfg.elm_min_peak;
thres_elm_low = cfg.thres_elm_low;
smooth_points = cfg.smooth_points;

elm_peak_loc = [];
elm_ind = [];

if min_dist > length(data)-2
    min_dist = length(data)-2;
end

if length(data) >= 3
    [elm_peak, elm_peak_loc] = findpeaks(data, 'MinPeakHeight', min_peak, 'MinPeakDistance', min_dist);
else
    return
end

% if isempty(elm_peak_loc)
%     return
% end

elm_ind_cand = [];
for i=1:length(elm_peak_loc)
    smooth_pnt_half = round(smooth_points/2);
    tmp_ind = elm_peak_loc(i) + [-smooth_pnt_half smooth_pnt_half];
    tmp_ind(1) = max([tmp_ind(1) 1]);
    tmp_ind(2) = min([tmp_ind(2) length(data)]);
    tmp_ind = [tmp_ind(1) elm_peak_loc(i) tmp_ind(2)];
    flag = prod(diff(data(tmp_ind)));
    if flag > 0
        elm_ind_cand(end+1) = i;
    end
end

elm_peak_loc(elm_ind_cand) = [];
elm_peak(elm_ind_cand) = [];

if isempty(elm_peak_loc)
    return
end

target_inds{1} = 1:elm_peak_loc(1);
p = elm_peak(1);
for i=1:length(elm_peak_loc)-1
    target_inds{end+1} = elm_peak_loc(i):elm_peak_loc(i+1);
    p(end+1) = elm_peak(i);
end
target_inds{end+1} = elm_peak_loc(end):length(data);
p(end+1) = elm_peak(end);

elm_ind = [];
for i=1:length(target_inds)
    tmp_ind = target_inds{i};
    ind_cand = tmp_ind(data(tmp_ind) >= p(i)*thres_elm_low);
    elm_ind(end+1:end+length(ind_cand)) = ind_cand;
end
elm_ind = sort(unique(elm_ind));
