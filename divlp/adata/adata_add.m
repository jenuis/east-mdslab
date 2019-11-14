function data = adata_add(file_path, var_name, input_arg)
%% function adata_add(file_path, var_name, input_arg);
% function data = adata_add(data, var_name, input_arg)
var_name = parse_str_option(var_name);
col_ind = adata_getrowno(var_name);
if ischar(file_path)
    load(file_path);
else
    data = file_path;
end
if nargin == 3 && ~iscell(input_arg)
    input_arg = {input_arg};
end
if colexist(data, col_ind)
    if nargin == 3 && haselement(input_arg, 'overwrite')
        warning('data has already exist, will be overwritten!')
    else
        warning('data has already exist, now exit!')
        return
    end
end
switch var_name
    case {'tet','tetar','divte','tarte'}
        arg_len = length(input_arg);
        fit_avg = input_arg{1};
        position_tag = input_arg{2};
        port_name = input_arg{3};
        if arg_len == 3
            tree_name = 'east_1';
            avg_len = 1;
        elseif arg_len == 4
            tree_name = input_arg{4};
            avg_len = 1;
        else
            tree_name = input_arg{4};
            avg_len = input_arg{5};
        end  
        data = add_divte(data, col_ind, fit_avg, position_tag, port_name, tree_name, avg_len);
    case {'rpeak','r0'}
        mat_dir = input_arg{1};
        data = add_rpeak(data, col_ind, mat_dir);
    case {'r', 'majorradius', 'majorr'}
        data = add_efit_var(data, col_ind, 'maxis_r');
    case {'a', 'minorradius', 'minorr'}
        data = add_efit_var(data, col_ind, 'a');
    case {'vp','v','vloop'}
        data = add_proc(data, col_ind, @proc_vp, input_arg{1});
    case {'needge'}
        data = add_proc(data, col_ind, @proc_ne_edge, input_arg{1});
    case {'prad'}
        data = add_proc(data, col_ind, @proc_prad, input_arg{1});
    case {'te0'}
        data = add_proc(data, col_ind, @proc_tecore, input_arg{1});
    case {'betap'}
        data = add_proc(data, col_ind, @proc_betap, input_arg{1});
    case {'betat'}
        data = add_proc(data, col_ind, @proc_betat, input_arg{1});
    case {'lambdaintraw','lamintraw'}
        mat_dir = input_arg{1};
        [res, ind] = haselement(input_arg, 'mean');
        if res
            avg_method = input_arg{ind};
        else
            [res, ind] = haselement(input_arg, 'median');
            if res
                avg_method = input_arg{ind};
            else
                avg_method = 'mean';
            end
        end
        if strfind(mat_dir, '.mat')
            data = add_lamintraw_file(data, col_ind, mat_dir, avg_method);
        else
            data = add_lamintraw_dir(data, col_ind, mat_dir, avg_method);
        end
    case {'deltabot', 'deltabottom'} 
        data = add_proc(data, col_ind, @proc_tribot, input_arg{1});
    otherwise
            error('Invalid var name!');
end
if ischar(file_path)
    save(file_path, 'data');
end

function data = add_divte(data, col_ind, fit_avg, position_tag, port_name, tree_name, avg_len)
%% control
auto_revise = 0;
phy_name = 'te';
%% main
shotlist = adata_extract(data, 'shot');
u_shotlist = unique(shotlist);
for i=1:length(u_shotlist)
    shotno = u_shotlist(i);
    shot_ind = find(shotlist == shotno);
    time = adata_extract(data(:, shot_ind), 'time');
    time_range = [min(time)-2*fit_avg max(time)+2*fit_avg];
    prb_te = prb_load(shotno, position_tag, port_name, phy_name, time_range, struct(), tree_name, avg_len, auto_revise);
    for j=1:length(shot_ind)
        tmp_prbte = signal_slice(prb_te, [-.5 .5]*fit_avg + time(j));
        tmp_te = median(median(tmp_prbte.data, 'omitnan'), 'omitnan');
        data{col_ind, shot_ind(j)} = tmp_te;
    end
end

function data = add_rpeak(data, col_ind, mat_dir)
[src_shotlist, src_filelist] = foldershotlist(mat_dir, '*.mat');

shotlist = adata_extract(data, 'shot');
u_shotlist = unique(shotlist);
for i=1:length(u_shotlist)
    shotno = u_shotlist(i);
    shot_ind = find(shotlist == shotno);
    tmp_data = data(:, shot_ind);
    
    time = adata_extract(tmp_data, 'time');
    
    src_ind = find(src_shotlist == shotno, 1);
    load(src_filelist{src_ind});
    src_time = get_fits_time(fits);
    for j=1:length(shot_ind)
        tmp_fit = fits{src_time == time(j)};
        tmp_rpeak = tmp_fit.fit_res.eich.coeff(4);
        data{col_ind, shot_ind(j)} = tmp_rpeak;
    end
end

function data = add_lamintraw_dir(data, col_ind, mat_dir, avg_method)
[src_shotlist, src_filelist] = foldershotlist(mat_dir, '*.mat');

shotlist = adata_extract(data, 'shot');
u_shotlist = unique(shotlist);
for i=1:length(u_shotlist)
    shotno = u_shotlist(i);
    shot_ind = find(shotlist == shotno);
    tmp_data = data(:, shot_ind);
    
    time = adata_extract(tmp_data, 'time');
    
    src_ind = find(src_shotlist == shotno, 1);
    load(src_filelist{src_ind});
    src_time = get_fits_time(fits);
    for j=1:length(shot_ind)
        tmp_fit = fits{src_time == time(j)};
        
        tmp_fit_data = tmp_fit.fit_data;
        tmp_fit_data = fitdatamean(tmp_fit_data, avg_method);
        tmp_ybg = tmp_fit.fit_res.eich.coeff(5);
        tmp_lamint_raw = cal_lambda_int(tmp_fit_data.xdata, tmp_fit_data.ydata, tmp_ybg);
        
        data{col_ind, shot_ind(j)} = tmp_lamint_raw;
    end
end


function data = add_lamintraw_file(data, col_ind, mat_file, avg_method)
load(mat_file);
for i=1:size(data,2)
    tmp_fit = fits{i};
    
    tmp_fit_data = tmp_fit.fit_data;
    tmp_fit_data = fitdatamean(tmp_fit_data, avg_method);
    tmp_ybg = tmp_fit.fit_res.eich.coeff(5);
    tmp_lamint_raw = cal_lambda_int(tmp_fit_data.xdata, tmp_fit_data.ydata, tmp_ybg);
    
    data{col_ind, i} = tmp_lamint_raw;
end


function data = add_efit_var(data, col_ind, efit_name)
shotlist = adata_extract(data, 'shot');
u_shotlist = unique(shotlist);
for i=1:length(u_shotlist)
    shotno = u_shotlist(i);
    shot_ind = find(shotlist == shotno);
    time = adata_extract(data(:, shot_ind), 'time');
    efit_info = efit_map(shotno, [], 1, [], 1);
    dt = median(diff(efit_info.time), 'omitnan');
    for j=1:length(shot_ind)
        tmp_ind = findtime(efit_info.time, time(j));
        data{col_ind, shot_ind(j)} = efit_info.(efit_name)(tmp_ind);
    end
end

function data = add_proc(data, col_ind, fun, fit_avg)
shotlist = adata_extract(data, 'shot');
u_shotlist = unique(shotlist);
for i=1:length(u_shotlist)
    shotno = u_shotlist(i);
    shot_ind = find(shotlist == shotno);
    time = adata_extract(data(:, shot_ind), 'time');
    
    sig = fun(shotno);
    for j=1:length(shot_ind)
        time_range = [-.5 .5]*fit_avg + time(j);
        if sig.status
            try
                tmp_vp = signal_slice(sig, time_range);
                tmp_vp = mean(tmp_vp.data, 'omitnan');
            catch
%                 warning(err);
                tmp_vp = nan;
            end
        else
            tmp_vp = nan;
        end
        data{col_ind, shot_ind(j)} = tmp_vp;
    end
end

function col_exist = colexist(data, col_ind)
total_colno = size(data,1);
col_exist = 0;
if col_ind <= total_colno && ~isempty([data{col_ind,:}])
    col_exist = 1;
end

