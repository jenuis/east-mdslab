function tar_ind = findvaluefloor(arr, tar)
tar_ind = [];
if length(unique(arr)) ~= length(arr)
    error('array has duplicate value!')
end
[arr_sort, sort_ind] = sort(arr);
ind = find((arr_sort - tar) <= 0);
if isempty(ind)
    return
end
tar_ind = sort_ind(ind(end));
