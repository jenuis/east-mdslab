function [x, y, remove_inds] = remove_outliers(x, y, fig)
%% check arguments
if nargin == 3
    figure(fig);
end
%% get figure
hold_status = ishold(gca);
%% perform removing
diff_x = mean(abs(diff(x)));
diff_y = mean(abs(diff(y)));
remove_inds = [];
while 1
    %% ginput
    [in_x, in_y, button] = ginput(2);
    button = [num2str(button(1)) num2str(button(2))];
    %% check if a point is selected
    in_x_mean = mean(in_x);
    in_y_mean = mean(in_y);
    in_x_diff = abs(diff(in_x));
    in_y_diff = abs(diff(in_y));
    tar_x_ind = findvalue(x, in_x_mean);
    point_selected = 0;
    if in_x_diff/diff_x < 0.01 && in_y_diff/diff_y < 0.01 && abs(in_x_mean - x(tar_x_ind))/diff_x < 0.1 && abs(in_y_mean - y(tar_x_ind))/diff_y < 0.1
        selected_ind = round(findvalue(x,mean(in_x)));
        point_selected = 1;
    end
    %% trying to removed or restore a point
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
            if ~hold_status
                hold on
            end
            plot(to_be_removed_x, to_be_removed_y, 'rx', 'markersize', 10)
            if ~hold_status
                hold off
            end
            fprintf(1, '(%f, %f) is removed\n', to_be_removed_x, to_be_removed_y)
        end
    elseif strcmp(button, '33')
        if already_removed
            remove_inds(remove_inds==selected_ind) = [];
            if ~hold_status
                hold on
            end
            plot(to_be_removed_x, to_be_removed_y, 'wx', 'markersize', 10)
            if ~hold_status
                hold off
            end
            fprintf(1, '(%f, %f) is recoverd\n', to_be_removed_x, to_be_removed_y)
        end
    else
        break
    end
end
x(remove_inds) = [];
y(remove_inds) = [];
