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
        plotsignal(pow);
        hold on
        legend_names{end+1} = pow_names{j};
    end
end
if ~isempty(legend_names)
    xlabel('Time [s]');
    ylabel('Power [kW]');
    legend(legend_names,'location','eastoutside');
end