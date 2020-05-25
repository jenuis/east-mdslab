function scaleyaxisauto(fig, x_lim)
if nargin == 0
    fig = gcf;
end
if nargin <= 1
    x_lim = [];
end

if isempty(x_lim)
    use_default_xlim = 1;
else
    use_default_xlim = 0;
end

figure(fig);

subids = getsubplots;

for i=1:length(subids)
    lines = getlines(subids(i));
    subplot(subids(i))
    if use_default_xlim
        x_lim = xlim;
    end
    y_lim = [];
    for j=1:length(lines)
        l = lines(j);
        x_lim = mergeintervals(x_lim, [min(l.XData) max(l.XData)]);
        rng = findvalue(l.XData, x_lim);
        y = l.YData(rng(1):rng(2));
        y_lim = [y_lim [min(y) max(y)]];
        y_lim = [min(y_lim) max(y_lim)];
    end
    if ~isempty(lines)
        y_lim = y_lim + [-1 1]*diff(ylim)*0.05;
        ylim(y_lim)
    end
end