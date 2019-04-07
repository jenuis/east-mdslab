%% Xiang Liu@19.3.15
% call plasmapara and plot
function plasmapara_plot(shotno, col_no, dt)
%% CONSTANTS and Controls
if nargin == 1
    col_no = 2;
    dt = 0.05;
elseif nargin == 2
    dt = 0.05;
end
sig_list = {...
    'ip',...
    'ne',...
    'wmhd',...
    'q95',...
    'vloop',...
    'prad',...
    'lhw',...
    'icrf',...
    'ech',...
    'nbi',...
    'delta',...
    'kappa',...
    };
row_no = ceil(length(sig_list)/col_no);
fig_pos_w_s = 0;
%% check shot and load data
if nargin == 0
    m = mds; shotno = m.mdscurrentshot;
end
ip = proc_ip(shotno);
if ~ip.status
    return
end
time_range_wide = [0 max(ip.flat_time)+1.5];
time_array = min(time_range_wide):dt:max(time_range_wide);
pp = plasmapara(shotno, time_array);
if ~fieldexist(pp, 'time') && ~fieldexist(pp, 'shotno')
    return
end
%% plot signals
sig_no = length(sig_list);
fig_dw = 0.9/col_no;
for i=1:sig_no
    fig_no = floor((i-1)/row_no);
    fig(330+fig_no)
    setfigpostion([fig_pos_w_s+fig_no*fig_dw 0.1 fig_dw 0.9])
    set(gca, 'fontsize', 20)
    sig_name = sig_list{i};
    if ~fieldexist(pp, sig_name)
        continue
    end
    if strcmp(sig_name, 'wmhd')
        pp.(sig_name) = pp.(sig_name)*1e-6;
    end
    subplot_no = mod(i-1, row_no)+1;
    subplot(row_no, 1, subplot_no)
    plot(pp.time, pp.(sig_name),'k','linewidth',2);
    legend(sig_name)
    xlim(time_range_wide)
    if subplot_no == 1
        title(num2str(shotno, '#%d'))
    end
    if subplot_no == row_no
        samexaxis('join', 'ytac')
        xlabel('Time [s]')
    end
end
%% disp shot para summaries
pp_mean = plasmapara_mean(pp);
field_names = fieldnames(pp_mean);
msg = {};
for i=1:length(field_names)
    fname = field_names{i};
    data = pp_mean.(fname);
    if length(data) > 1
        continue
    end
    msg{end+1} = [sprintf('%s : ', fname) num2str(data)];
end
msgbox(msg);