function new_range = mergeintervals(base_range, sec_range)
if ~(length(base_range) == length(sec_range) && length(base_range) == 2)
    error('Invalid input!')
end
base_range = sort(base_range);
sec_range = sort(sec_range);
[~,~,all_in] = inrange(sec_range, base_range);
if all_in
    new_range = base_range;
    return
end

[val, ind, all_in] = inrange(base_range, sec_range);
if all_in
    new_range = sec_range;
    return
end
if isempty(ind)
    new_range = [];
    return
end
if ind == 1
    new_range = [val base_range(2)];
elseif ind == 2
    new_range = [base_range(1) val];
else
    error('What?')
end
if diff(new_range) == 0
    new_range = [];
end