function [data, ind] = adata_rmnan(data, colno_list)
col_no = size(data, 1);
if nargin == 1
    colno_list = 1:col_no;
end

ind = true(1,size(data, 2));
for i=1:length(colno_list)
    ind = ind & ~isnan([data{colno_list(i), :}]);
end
data = data(:, ind);