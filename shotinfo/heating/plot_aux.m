%% Method for plotting auxilary heating struct
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
function plot_aux(aux)
heat_names = fieldnames(aux);
legend_names = {};
for i=1:length(heat_names)
    heat_type = aux.(heat_names{i});
    if ~isstruct(heat_type)
        continue
    end
    pow_names = fieldnames(heat_type);
    for j=1:length(pow_names)
        pow = heat_type.(pow_names{j});
        plot(pow.time, pow.data*1e-3, 'linewidth', 2);
        hold on
        legend_names{end+1} = pow_names{j};
    end
end
if ~isempty(legend_names)
    xlabel('Time [s]');
    ylabel('Power [MW]');
    legend(legend_names,'location','best', 'orientation', 'horizontal');
end