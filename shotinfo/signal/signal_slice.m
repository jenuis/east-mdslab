function signal_out = signal_slice(signal_in, time_range)
    time_ind = timerngind(signal_in.time, time_range);
    sub_names = fieldnames(signal_in);
    for i =1:length(sub_names)
        sub_field = signal_in.(char(sub_names(i)));
        shape = size(sub_field);
        if max(shape) == 1 || max(shape) ~= length(signal_in.time) % constant
            signal_out.(char(sub_names(i))) = sub_field;
        elseif min(shape) == 1 % 1-D array
            signal_out.(char(sub_names(i))) = sub_field(time_ind(1):time_ind(2));
        else % 2-D array
            if shape(1) == length(signal_in.time)
                 signal_out.(char(sub_names(i))) = sub_field(time_ind(1):time_ind(2),:);
            else
                 signal_out.(char(sub_names(i))) = sub_field(:,time_ind(1):time_ind(2));
            end
        end
    end
end
