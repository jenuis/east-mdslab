function data = adata_update(data, var_name, var_val)
data_len = size(data,2);
if data_len ~= length(var_val)
    error('varialbe value not same as data dim:2!')
end
var_no = adata_getrowno(var_name);
for i=1:data_len
    data{var_no, i} = var_val(i);
end