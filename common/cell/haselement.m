function [res, ind] = haselement(cellarray, cellvalue)
% http://stackoverflow.com/questions/31023046/matlabhow-to-check-if-a-cell-element-already-exists-in-a-cell-array
log_ind = cellfun(@(x) isequal(x, cellvalue), cellarray);
res = any(log_ind);
ind = [];
if res
    ind = find(log_ind == 1, 1);
end
