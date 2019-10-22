function subplot_objs = getsubplots(fig_obj, sub_id)
if nargin == 0
    fig_obj = gcf;
end
subplot_objs = findobj(fig_obj,'Type','Axes');
subplot_objs = flip(subplot_objs); % do not use fliplr
if nargin ==2
    subplot_objs = subplot_objs(sub_id);
end