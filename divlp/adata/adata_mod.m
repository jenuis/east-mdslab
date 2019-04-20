function [data, sel_ind] = adata_mod(data, mod_type, mod_arg)
%% check arugmetns
mod_type = parse_str_option(mod_type);
adata_info
%% main
data_size = size(data);
sel_ind = true(1, data_size(2) );
switch mod_type
    %% gerneral operation
    case {'abs'}
        if ischar(mod_arg)
            mod_arg = {mod_arg};
        end
        for i=1:length(mod_arg)
            var_name = mod_arg{i};
            var_no = adata_getrowno(var_name);
            for j=1:data_size(2)
                data{var_no,j} = abs(data{var_no,j});
            end
        end
    case {'unit'}
        var_name = mod_arg{1};
        unit_fac = mod_arg{2};
        var_val = adata_extract(data, var_name);
        var_val = var_val*unit_fac;
        data = adata_update(data, var_name, var_val);
    case {'norm','normalize'}
        if ~iscell(mod_arg) || length(mod_arg) < 2 ||...
                ~ischar(mod_arg{1})
            error('Wrong arguments for filter operation!');
        elseif length(mod_arg) == 2
            mod_arg{end+1} = @(x) x;
        end
        var_name_tar = mod_arg{1};
        var_name_norm = mod_arg{2};
        func = mod_arg{3};
        
        var_val_tar  = adata_extract(data, var_name_tar);
        var_val_norm = adata_extract(data, var_name_norm);
        var_val_tar = var_val_tar./func(var_val_norm);
        data = adata_update(data, var_name_tar, var_val_tar);
        DataType{adata_getrowno(var_name_tar)} = [DataType{adata_getrowno(var_name_tar)} '_{norm}'];
    %% Filter data, data might be reduced
    case {'filter'}
        if ~iscell(mod_arg) || length(mod_arg) ~= 2 ||...
                ~ischar(mod_arg{1}) || length(mod_arg{2}) ~= 2
            error('Wrong arguments for filter operation!');
        end
        var_name = mod_arg{1};
        data_range = sort(mod_arg{2});
        tmp_val = adata_extract(data, var_name);
        sel_ind = tmp_val >= data_range(1) & tmp_val <= data_range(2);
    case {'limpowbit'}
        if length(mod_arg) ~= 4
            error('Wrong pow bit inputted!')
        end
        powbit = adata_extract(data, 'powbit');
        sel_bit_ind = mod_arg == 0 | mod_arg == 1; 
        sel_bit = logical(mod_arg);
        for i=1:length(powbit)
            res_bit = dec2bit(powbit(i), 4);
            if ~isequal(res_bit(sel_bit_ind), sel_bit(sel_bit_ind))
                sel_ind(i) = false;
            end
        end
        
    %% modify to similiar definition
    case {'qcyl','qcylinder'}
%         [q95,var_no] = adata_extract(data, 'q95');
        R = adata_extract(data, 'R');
        a = adata_extract(data, 'a');
        bp = adata_extract(data, 'Bp');
        bt = adata_extract(data, 'Bt');
        qcyl = a.*bt./R./bp;
        data = adata_update(data, 'qcyl', qcyl);
        DataType{adata_getrowno('q95')} = 'q_{cyl}';
    case {'lpara'}
        for i=1:data_size(2)
            data{11,i} = data{10,i}*data{11,i};
            data{12,i} = data{10,i}*data{12,i};
        end
    case {'fgw','normne','nenorm'}
        [ne, var_no] = adata_extract(data, 'ne'); % 10e19
        ip = adata_extract(data, 'ip');
        a = adata_extract(data, 'a');
        
        ngw = ip./(pi*a.^2); % 10e20
        ngw = ngw*10; % 10e19
        data = adata_update(data, 'ne', ne./ngw);
        DataType{var_no}  = 'f_{GW}';
    case {'power','pow', 'p'}
%         if ischar(mod_arg)
%             mod_arg = {mod_arg};
%         end
%         operation = mod_arg{1};
        operation = mod_arg;
        if isempty(operation) ||...
                haselement({'pin','pinput'}, parse_str_option(operation))
            return
        end
       
        [paux, var_no] = adata_extract(data, 'P_input'); % [MW]
        
        ip = adata_extract(data, 'ip'); % [MA]
        vp = adata_extract(data, 'vp'); % [V]
        pohm = abs(ip.*vp); % [MW]
        
        ptot = paux + pohm;
        
        switch operation
            case 'ptot'
                pin = ptot;
                var_name_new = 'P_{tot}';
            case 'psol'
                prad = adata_extract(data, 'P_rad'); % [MW]
                psol = ptot - prad;
                pin = psol;
                var_name_new = 'P_{SOL}';
            otherwise
                error('Invalid operation for calculating Power!')
        end
        data = adata_update(data, 'pin', pin);
        DataType{var_no} = var_name_new;
    %% sepecific operation
    %% for compatibility
    case {'unitwmhd','wmhdunit'}
%         for i=1:data_size(2)
%             data{19,i} = data{19,i}*1e-6; % wmhd [MJ]
%         end
        data = adata_mod(data, 'unit', {'wmhd', 1e-6});
    case {'absbt', 'btabs'}
%         for i=1:data_size(2)
%             data{5,i} = abs(data{5,i}); % abs(Bt)
%         end
        data = adata_mod(data, 'abs', 'bt');
    case {'absvp','absvloop'}
%         row_vp = adata_getrowno('vp');
%         for i=1:data_size(2)
%             data{row_vp, i} = abs(data{row_vp, i});
%         end
        data = adata_mod(data, 'abs', 'vloop');
    otherwise
        error('Unsupported Type!');
end
if ~sum(sel_ind)
    warning('output data will be empty!')
end
if sum(sel_ind) ~= data_size(2)
    data = data(:, sel_ind);
end
