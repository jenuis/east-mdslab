function [row_val, row_no] = adata_extract(data, row_no, col_ind)
if nargin == 2
    col_ind = true(1, size(data, 2));
end
if ischar(row_no)
    var_name = row_no;
    try
        row_no = adata_getrowno(var_name);
    catch
        row_val = adata_cal(data, var_name);
        row_no = nan;
        return
    end
else iscell(row_no)
    error('row_no or string var name!');
end
row_val = [data{row_no, col_ind}];

function var_val = adata_cal(data, var_name)
var_name = parse_str_option(var_name);
switch var_name
    case {'pohm','pohmic','powohm','powerohm','powerohmic'}
        ip = adata_extract(data, 'ip');
        vp = adata_extract(data, 'vp');
        var_val = abs(vp).*ip;
    otherwise
        error('Invalid var name!');
end