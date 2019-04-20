function [data_new, data_err] = adata_merge(data, operation)
if isempty(operation)
    data_new = data;
    data_err = {};
    return
end
operation = parse_str_option(operation);
switch operation
    case {'shot','shotno'}
        [data_new, data_err] = merge_shotno(data);
    case 'powbit'
        [data_new, data_err] = merge_powbit(data);
    otherwise
        error('Unrecognized operation!');
end
% fix shotno for data_err
if ~isempty(data_new)
    [~, ind] = adata_extract(data_new, 'shot');
    data_err(ind,:) = data_new(ind,:);
end

function [data_new, data_err] = merge_powbit(data)
data_new = {};
data_err = {};
shot_ind = adata_getrowno('shotno');
powbit_ind = adata_getrowno('powbit');

shotlist=[data{shot_ind,:}];
powbit=[data{powbit_ind,:}];
    
u_shotlist = unique(shotlist);
for i=1:length(u_shotlist)
    ind_shot = shotlist == u_shotlist(i);
    u_powbit = unique(powbit(ind_shot));
%     if length(u_powbit) > 1
%         disp(u_powbit)
%     end
    for j=1:length(u_powbit)
        ind_powbit = powbit == u_powbit(j);
        ind = ind_shot & ind_powbit;
        [data_new, data_err] = add2data(data_new, data_err, data, ind);
    end
end

function [data_new, data_err] = merge_shotno(data)
data_new = {};
data_err = {};
shot_ind = adata_getrowno('shotno');

shotlist=[data{shot_ind,:}];
    
u_shotlist = unique(shotlist);
for i=1:length(u_shotlist)
    ind_shot = shotlist == u_shotlist(i);
    ind = ind_shot;
    [data_new, data_err] = add2data(data_new, data_err, data, ind);    
end

function [data_new, data_err] = add2data(data_new, data_err, data, data_ind)
varno = size(data, 1);

if sum(data_ind)
    data_new{1, end+1} = mean( [data{1, data_ind}], 'omitnan' );
    data_err{1, end+1} = std(  [data{1, data_ind}], 'omitnan' );
    for i=2:varno
        data_new{i, end} = mean( [data{i, data_ind}], 'omitnan' );
        data_err{i, end} = std(  [data{i, data_ind}], 'omitnan' );
    end
end
