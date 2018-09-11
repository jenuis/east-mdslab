function [res, flat_ind] = haspulse(data)
flat_ind = flattop(data);
if isempty(flat_ind)
    res = 0;
    return
end
flat_data = data(flat_ind(1):flat_ind(2));
back_data = data;
back_data(flat_ind(1):flat_ind(2)) = [];
res = abs(mean(flat_data)/mean(back_data)) > 1.5;