function [x, y, remove_inds] = remove_outliers(x, y, varargin)
%% check arguments
Args = struct(...
    'tolerance', 0.01, ...
    'fig', [] ...
    );
Args = parseArgs(varargin, Args);
tolerance = Args.tolerance;
fig = Args.fig;
if ~isempty(fig)
    figure(fig);
end
%% get figure
if ishold(gca)
    hold_status = 'on';
else
    hold_status = 'off';
end
%% perform removing
x_min = min(x); x_max = max(x); x_pp = x_max-x_min;
y_min = min(y); y_max = max(y); y_pp = y_max-y_min;
norm_x = (x-x_min)/x_pp;
norm_y = (y-y_min)/y_pp;
remove_inds = [];
f = [];
while 1
    %% ginput
    [in_x, in_y, button] = ginput(2);
    button = [num2str(button(1)) num2str(button(2))];
    %% check if a point is selected
    in_x_mean = (mean(in_x)-x_min)/x_pp;
    in_y_mean = (mean(in_y)-y_min)/y_pp;
    in_x_diff = (abs(diff(in_x))-x_min)/x_pp;
    in_y_diff = (abs(diff(in_y))-y_min)/y_pp;
    
    x_inds = abs(norm_x - in_x_mean) < tolerance;
    y_inds = abs(norm_y - in_y_mean) < tolerance;
    selected_ind = find(x_inds & y_inds==1);
    
    point_selected = 0;
    if in_x_diff < tolerance && in_y_diff < tolerance && length(selected_ind) == 1
        point_selected = 1;
    end
    %% trying to remove or restore a point
    if ~point_selected
        if ~haselement({'11', '33'}, button)
            break
        else
            continue
        end
    end
    
    already_removed = ~isempty(find(remove_inds == selected_ind, 1));
    to_be_removed_x = x(selected_ind);
    to_be_removed_y = y(selected_ind);
    if strcmp(button, '11')
        if ~already_removed
            remove_inds(end+1) = selected_ind;
            fprintf(1, '(%f, %f) is removed\n', to_be_removed_x, to_be_removed_y)
        end
    elseif strcmp(button, '33')
        if already_removed
            remove_inds(remove_inds==selected_ind) = [];
            fprintf(1, '(%f, %f) is recoverd\n', to_be_removed_x, to_be_removed_y)
        end
    else
        break
    end
    %% plot removed points
    if ~isempty(f)
        f.delete;
    end
    hold on
    f = plot(x(remove_inds), y(remove_inds), 'rx', 'markersize', 10);
    hold(hold_status);
end
x(remove_inds) = [];
y(remove_inds) = [];
