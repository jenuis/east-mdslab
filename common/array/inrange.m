function [test_new, test_ind, all_in_range] = inrange(range, test)
% if length(range)~=2 || diff(range) == 0
if length(range)~=2
    error('Invalid input range!');
end
all_in_range = 1;
range = sort(range);
test_ind = [];
for i = 1:length(test)
    if test(i) < range(1) || test(i) > range(2)
        all_in_range = 0;
        continue
    end
    test_ind(end+1) = i;
end
test_new = test(test_ind);