classdef prbfit
    methods(Static)
        function efit_info = gen_efitinfo(prbd)
            %% check arguments
            if ~isa(prbd, 'prbdataraw') && ~isa(prbd, 'prbdatacal')
                error('prbd should be prbdataraw or prbdatacal type!')
            end
            %% gen efit info
            shotno = prbd.shotno;
            efit_info = efit_map(shotno, prbd.prb_extract_distinfo('rz'), 1);
            efit_info.shotno = shotno;
            efit_info.position_tag = prbd.prb_get_postag();
            efit_info.port_name = prbd.prb_get_portname();
        end
        
        function efit_info = interp_efitinfo(efit_info, interp_no, field_name)
            %% check arguments
            if nargin == 1
                interp_no = 2;
                field_name = 'map_rel_r';
            elseif nargin == 2
                field_name = 'map_rel_r';
            end
            %% extract and interp efit info
            efitinfo_tmp.time = linspace(min(efit_info.time), max(efit_info.time), length(efit_info.time)*(interp_no+1));
            efitinfo_tmp.(field_name) = [];
            efitinfo_tmp.shotno = efit_info.shotno;
            efitinfo_tmp.position_tag = efit_info.position_tag;
            efitinfo_tmp.port_name = efit_info.port_name;
            channel_no = size(efit_info.(field_name), 1);
            for i=1:channel_no
                for j=1:length(efitinfo_tmp.time)
                    efitinfo_tmp.(field_name)(i,j) = interp1(efit_info.time, efit_info.(field_name)(i,:), efitinfo_tmp.time(j), 'PCHIP');
                end
            end
            efit_info = efitinfo_tmp;
            efit_info.interp_no = interp_no;
        end
        
        function rrsep = gen_rrsep(prbd, efit_info, varargin)
            %% check arguments
            if ~isa(prbd, 'prbdataraw') && ~isa(prbd, 'prbdatacal')
                error('prbd should be prbdataraw or prbdatacal type!')
            end
            if ~prbd.prb_is_samebranch(efit_info)
                error('prbd and efit_info are not under same branch!')
            end
            Args.interp_no = 2;
            Args = parseArgs(varargin, Args);
            %% check merged time range
            time_range = mergeintervals(efit_info.time([1 end]), prbd.time([1 end]));
            if isempty(time_range)
                error('efit_info time not overlap with prbd time!')
            end
            %% interp efit_info
            if ~fieldexist(efit_info, 'interp_no')
                efit_info = prbfit.interp_efitinfo(efit_info, Args.interp_no);
            end
            %% gen rrsep
            channel_no = size(prbd.data, 1);
            time_inds = findvalue(prbd.time, time_range);
            rrsep.time = prbd.time(time_inds(1):time_inds(end));
            time_length = length(rrsep.time);
            rrsep.data = zeros(channel_no, time_length);
            for j=1:time_length
                ind = findvalue(efit_info.time, rrsep.time(j));
                rrsep.data(:,j) = efit_info.map_rel_r(:,ind);
            end
            %% tag rrsep
            rrsep.shotno = efit_info.shotno;
            rrsep.position_tag = efit_info.position_tag;
            rrsep.port_name = efit_info.port_name;
        end
        
        function res = match_rrsep(prbd, rrsep)
            res = 0;
            if ~isstruct(rrsep) || ...
                    ~fieldexist(rrsep, 'shotno') || ...
                    ~fieldexist(rrsep, 'position_tag') || ...
                    ~fieldexist(rrsep, 'port_name') || ...
                    ~prbd.prb_is_samebranch(rrsep)  || ...
                    ~fieldexist(rrsep, 'time') || ...
                    ~fieldexist(rrsep, 'data')
                warning('not the same branch or rrsep not valid!')
                return
            end
            prbd_time_diff = mean(diff(prbd.time));
            if abs(mean(diff(rrsep.time)) - prbd_time_diff)/prbd_time_diff > 1e-3 
                warning('samping rate not match!')
                return
            end
            time_range = mergeintervals(prbd.time([1 end]), rrsep.time([1 end]));
            if isempty(time_range)
                warning('time not overlapped!')
                return
            end
            if size(rrsep.data,1) ~= size(prbd.data,1)
                warning('rrsep.data has different channel_no from prbd.data!')
                return
            end
            res = 1;
        end
        
        function fit_data = fitdata_gen(prbd, xaxis, time_slice)
            %% check arguments
            if ~isnumeric(time_slice) || time_slice(end)-time_slice(1) < 0
                error('time_slice not valid!')
            end
            %% extract ydata
            prbd_time_inds = findtime(prbd.time, time_slice, 1);
            fit_data.ydata = prbd.data(:, prbd_time_inds(1):prbd_time_inds(end));
            fit_data.ytype = prbd.phy_type;
            ydata_size = size(fit_data.ydata);
            %% extract xdata
            if prbfit.match_rrsep(prbd, xaxis) %% R-Rsep
                xaxis_time_inds = findtime(xaxis.time, time_slice, 1);
                if diff(xaxis_time_inds) ~= diff(prbd_time_inds)
                    error('xaxis.time has different sampling rate from prbd.time!')
                end
                fit_data.xdata = xaxis.data(:, xaxis_time_inds(1):xaxis_time_inds(end));
                fit_data.xtype = 'rrsep';
            elseif isnumeric(xaxis) && length(xaxis) == ydata_size(1) %% dist2div
                fit_data.xdata = zeros(ydata_size);
                fit_data.xtype = 'dist2div';
                for i=1:ydata_size(2)
                    fit_data.xdata(:,i) = xaxis;
                end
            else
                error('xaxis is neither rrsep type or the dist2div!')
            end
            %% flatten fit_data
            if min(ydata_size) > 1
                total_len = prod(ydata_size);
                fit_data.xdata = reshape(fit_data.xdata, 1, total_len);
                fit_data.ydata = reshape(fit_data.ydata, 1, total_len);
            end
            %% remove nan
            ynan_inds = isnan(fit_data.ydata);
            if sum(ynan_inds)
                inds = ~isnan(fit_data.xdata) & ~ynan_inds;
                fit_data.xdata = fit_data.xdata(inds);
                fit_data.ydata = fit_data.ydata(inds);
            end
        end
        
        function fit_data = fitdata_combine(fit_data_list)
            if ~iscell(fit_data_list) && length(fit_data_list) < 2
                error('fit_data_list should have at least two elements!')
            end
            fit_data = fit_data_list{1};
            if fieldexist(fit_data, 'yerr')
                error('fit_data in the list should be raw data without averaging!')
            end
            for i=2:length(fit_data_list)
                if ~isequal(fit_data.xtype, fit_data_list{i}.xtype)
                    error('xtype not match!')
                end
                if ~isequal(fit_data.ytype, fit_data_list{i}.ytype)
                    error('ytype not match!')
                end
                fit_data.xdata = [fit_data.xdata fit_data_list{i}.xdata];
                fit_data.ydata = [fit_data.ydata fit_data_list{i}.ydata];
            end
        end
        
        function fit_data = fitdata_avg(fit_data, use_median)
            %% check arguments
            if nargin < 2
                use_median = 1;
            end
            %% set funs
            if use_median
                fun_avg = @median;
                fun_err = @mad;
            else
                fun_avg = @mean;
                fun_err = @std;
            end
            %% average fit_data
            x = fit_data.xdata;
            y = fit_data.ydata;
            x_u = unique(x); %% sorted automatically
            
            fit_data.xdata = x_u;
            fit_data.ydata = [];
            fit_data.yerr  = [];
            for i=1:length(x_u)
                inds = x==x_u(i);
                fit_data.ydata(i) = fun_avg(y(inds));
                fit_data.yerr(i)  = fun_err(y(inds));
            end
            %% set ymin
            [fit_data.ymin, ind] = min(fit_data.ydata);
            fit_data.ymin(2) = fit_data.yerr(ind);
            %% set ymax
            [fit_data.ymax, ind] = max(fit_data.ydata);
            fit_data.ymax(2) = fit_data.yerr(ind);
        end
        
        function [ydata, c] = fun_eich(coeff, xdata)
            if isnumeric(coeff)
                switch length(coeff)
                    case 3
                        c.r0 = 0;
                        c.bg = 0;
                    case 4
                        c.r0 = coeff(4);
                        c.bg = 0;
                    case 5
                        c.r0 = coeff(4);
                        c.bg = coeff(5);
                    otherwise
                        error('The length of coeff should be 3, 4 or 5!')
                end
                c.peak = coeff(1);
                c.lam  = coeff(2);
                c.S    = coeff(3);
                if nargin == 1
                    ydata = [];
                    return
                end
            elseif isstruct(coeff)
                c = coeff;
            else
                error('Unsupport coeff type!')
            end
            ydata = c.peak/2*exp((c.S/2/c.lam)^2 - (xdata - c.r0)/c.lam).*erfc(c.S/2/c.lam - (xdata - c.r0)/c.S) + c.bg;
        end
        
        function fit_res = eichfit(fit_data, varargin)
            %% check arguments
            if ~fieldexist(fit_data, 'xdata') || ~fieldexist(fit_data, 'ydata')
                error('fit_data is has no xdata or ydata field!')
            end
            Args = struct(...
                'ZeroBg', 0, ...
                'MsParallel', 0, ...
                'MsStartNo', 24, ...
                'FitBdry', [1000 100 100 50 100; 0 0 0 -50 -100]);
            Args = parseArgs(varargin, Args, {'MsParallel', 'ZeroBg'});
            %% set fit boundary
            ub = Args.FitBdry(1,:);
            lb = Args.FitBdry(2,:);
            if Args.ZeroBg
                ub(5) = 0; lb(5) = 0;
            elseif fieldexist(fit_data, 'ymin') && isnumeric(fit_data.ymin)
                ub(5) = sum(fit_data.ymin);
                lb(5) = -diff(fit_data.ymin);
            end
            ub(4) = max(fit_data.xdata);
            lb(4) = min(fit_data.xdata);
            ub(3) = ub(4) - lb(4);
            ub(2) = ub(3);
            ub(1) = max(fit_data.ydata)*10;
            %% fit data
            [coeff, fval, r2] = globaloptim(fit_data.xdata, fit_data.ydata, @prbfit.fun_eich, lb, ub, Args.MsStartNo, Args.MsParallel);
            [~, fit_res] = prbfit.fun_eich(coeff);
            fit_res.r2 = r2;
            fit_res.fval = fval;
        end
        
        function lambda_int = cal_lambda_int(fit_data, fit_res, varargin)
            Args.Method = 'median'; % {'median', 'left', 'right'}
            Args.Type = 'eich'; % {'eich', 'raw'}
            Args = parseArgs(varargin, Args);
            
            if strcmpi(Args.Type, 'raw')
                xdata = fit_data.xdata;
                ydata = fit_data.ydata;
                
                inds = isnan(xdata) | isnan(ydata);
                xdata(inds) = [];
                ydata(inds) = [];
            elseif strcmpi(Args.Type, 'eich')
                xdata = linspace(-30*fit_res.S, 30*fit_res.lam, 5000);
                ydata = prbfit.fun_eich(fit_res, xdata) - fit_res.bg;
            else
                error('Unknow Type!')
            end
            
%             plot(fit_data.xdata, fit_data.ydata, 'ko')
%             hold on
%             plot(xdata, ydata, 'r.:')
            
            % cal lambda_int
            ypeak = max(ydata);
            switch Args.Method
                case 'median'
                    lambda_int = abs(trapz(xdata(:), ydata(:)))/ypeak;
                    return
                case 'left'
                    lambda_int_portion = abs(diff(xdata)).*ydata(1:end-1);
                case 'right'
                    lambda_int_portion = abs(diff(xdata)).*ydata(2:end);
                otherwise
                    error('Unknow Method!')
            end
            lambda_int = sum(lambda_int_portion)/ypeak;
        end
        
        function fig = fitdata_plot(fit_data, fit_res)
            %% plot fit_data
            fig = errorbar(fit_data.xdata, fit_data.ydata, fit_data.yerr, 'k*', 'linewidth', 2, 'markersize', 8);
            set(gcf, 'color', 'w');
            set(gca, 'fontsize', 25);
%             setfigpostion('left');
            y_label = prbbase.prb_get_phytype(fit_data.ytype);
            if isequal(fit_data.xtype, 'dist2div')
                x_label = 'Distance to Divtor Corner [mm]';
            elseif isequal(fit_data.xtype, 'rrsep')
                x_label = 'R-R_{LCFS} [mm]';
            else
                error('Unknown xtype!')
            end
            xlabel(x_label)
            ylabel(y_label)
            xlim([min(fit_data.xdata) max(fit_data.xdata)]);
            ylim([min(fit_data.ydata -fit_data.yerr) max(fit_data.ydata+fit_data.yerr)]);
            if nargin == 1
                return
            end
            %% plot fit_res
            hold on
            x = linspace(min(fit_data.xdata), max(fit_data.xdata), 100);
            y = prbfit.fun_eich(fit_res, x);
            plot(x,y,'r','linewidth', 3);
            %% plot r0
            ax = vline(fit_res.r0, 'k:');
            set(ax, 'linewidth', 2);
            hold off
            %% disp fitting results
            fitres_str = {['\lambda = ' num2str(fit_res.lam,'%3.2f') ' [mm]']};
            fitres_str{end+1} = ['S = ' num2str(fit_res.S,'%3.2f') ' [mm]'];
            fitres_str{end+1} = ['R^2 = ' num2str(fit_res.r2,'%1.2f')];
            text(diff(xlim)*0.05+min(xlim),diff(ylim)*0.75+min(ylim), ...
                fitres_str, 'fontsize', 20, 'color', 'r');
        end
        
        function time_slices = slice_time(time, time_slice_len)
%         function time_slices = slice_time(time, time_range, time_slice_len)
            dt = mean(diff(time));
            if time_slice_len < dt
                time_slice_len = dt;
            end
%             time_range_diff = diff(time_range);
%             if time_slice_len > time_range_diff
%                 time_slice_len = time_range_diff;
%             end
%             [~, time] = timerngind(time, time_range);
            
            time_slices = {};
            while(~isempty(time))
                s = time(1);
                inds = find((time-s) <= time_slice_len);
                f = time(inds(end));
                time(inds) = [];
                if abs(f - s - time_slice_len) < dt
                    time_slices{end+1} = [s f];
                end
            end
        end
        
        function time_slices = slice_time_range(time_range, avg_time, slice_no)
            time = linspace(time_range(1) + avg_time, time_range(end) - avg_time, slice_no);
            if time(end) - time(1) < 0
                error('time_range is too smaller to fit avt_time!')
            end
            time_slices = cell(1, slice_no);
            for i=1:slice_no
                time_slices{i} = [-1 1]*avg_time/2 + time(i);
            end
        end
        
        function fits_res = fits(prbd, xaxis, varargin)
            %% check arguments
            if isa(prbd, 'prbdataraw') || isa(prbd, 'prbdatacal')
                cmb = 0;
            elseif iscell(prbd) && iscell(xaxis) && length(prbd) == length(xaxis)
                shotlist = [];
                postags = {};
                portnames = {};
                phytypes = {};
                data_sizes = [];
                for i=1:length(prbd)
                    shotlist = prbd{i}.shotno;
                    postags{end+1} = prbd{i}.prb_get_postag();
                    portnames{end+1} = prbd{i}.prb_get_portname();
                    phytypes{end+1} = prbd{i}.phy_type;
                    data_sizes = [data_sizes size(prbd{i}.data)];
                end
                if length(unique(shotlist)) ~= 1
                    error('elements in prbd have different shotno!')
                end
                if length(unique(postags)) ~= 1
                    error('elements in prbd have different postition_tag!')
                end
                if length(unique(portnames)) ~= length(prbd)
                    error('elements in prbd have duplicate port_name!')
                end
                if length(unique(phytypes)) ~= 1
                    error('elements in prbd have different phy_type!')
                end
                if length(unique(data_sizes)) ~= 2
                    error('elements in prbd have different data size!')
                end
                cmb = 1;
            else
                error('prbd and xaxis data type not supported!')
            end
            Args = struct(...
                'ZeroBg', 0, ...
                'MsParallel', 0, ...
                'MsStartNo', 24, ...
                'AvgTime', 0.05, ...
                'TimeSlices', []);
            Args = parseArgs(varargin, Args, {'ZeroBg', 'MsParallel'});
            fit_cfg = {...
                    'ZeroBg', Args.ZeroBg, ...
                    'MsParallel', Args.MsParallel, ...
                    'MsStartNo', Args.MsStartNo};
            %% gen time_slices
            if cmb
                prbd_1st = prbd{1};
                xaxis_1st = xaxis{1};
            else
                prbd_1st = prbd;
                xaxis_1st = xaxis;
            end
            if prbfit.match_rrsep(prbd_1st, xaxis_1st) %% R-Rsep
                time_range = mergeintervals(xaxis_1st.time([1 end]), prbd_1st.time([1 end]));
                if isempty(Args.TimeSlices)
                    time_inds = findtime(prbd_1st.time, time_range);
                    time = prbd_1st.time(time_inds(1):time_inds(end));
                    time_slices = prbfit.slice_time(time, Args.AvgTime);
                else
                    time_slices = {};
                    for i=1:length(Args.TimeSlices)
                        [~,~,status] = inrange(time_range, Args.TimeSlices{i});
                        if status
                            time_slices{end+1} = Args.TimeSlices{i};
                        end
                    end
                end
            else %% should be dist2div
                if isempty(Args.TimeSlices)
                    time_slices = prbfit.slice_time(prbd_1st.time, Args.AvgTime);
                else
                    time_slices = Args.TimeSlices;
                end
            end
            %% fit
            slice_no = length(time_slices);
            fits = struct();
            for i=1:length(time_slices)
                time_slice = time_slices{i};
                if cmb
                    prbd_len = length(prbd);
                    fit_data_list = cell(1, prbd_len);
                    for j=1:length(prbd)
                        fit_data_list{j} = prbfit.fitdata_gen(prbd{j}, xaxis{j}, time_slice);
                    end
                    fit_data = prbfit.fitdata_combine(fit_data_list);
                else
                    fit_data = prbfit.fitdata_gen(prbd, xaxis, time_slice);
                end
                fit_data = prbfit.fitdata_avg(fit_data);
                fits(i).time     = mean(time_slice);
                fits(i).fit_data = fit_data;
                fits(i).fit_res  = prbfit.eichfit(fit_data, fit_cfg{:});
                disp(['fitting progress: ' num2str(100*i/slice_no,'%5.1f') '%']);
            end
            fits_res.fits = fits;
            %% tag res
            fits_res.shotno = prbd_1st.shotno;
            fits_res.position_tag = prbd_1st.prb_get_postag();
            if cmb
                fits_res.port_name = portnames;
            else
                fits_res.port_name = {prbd_1st.prb_get_portname()};
            end
            fits_res.phy_type = prbd_1st.phy_type;
            fits_res.avg_time = Args.AvgTime;
        end
        
        function [fits_res, pda_out, rrsep_out] = fits_auto(shotno, position_tag, phy_type, varargin)
            %% check phy_type and call this function
            if isempty(phy_type)
                error('phy_type is empty!')
            elseif iscellstr(phy_type)
                if length(phy_type) > 1
                    fits_res = cell(1, length(phy_type));
                    [fits_res{1}, pda_out, rrsep_out] = prbfit.fits_auto(shotno, position_tag, phy_type{1}, varargin{:});
                    for i=2:length(phy_type)
                        fits_res{i} = prbfit.fits_auto(shotno, position_tag, phy_type{i}, 'PrbData', pda_out, 'RRsep', rrsep_out, varargin{:});
                    end
                    return
                end
                phy_type = phy_type{1};
            elseif ~ischar(phy_type)
                error('phy_type should be a cellstr or string!')
            end
            %% arguments
            Args = struct(...
                'PortName', [], ...
                'TimeRange', [], ...
                'TimeSlices', [], ...
                'AvgTime', 0.05, ...
                'ZeroBg', 0, ...
                'MsParallel', 0, ...
                'MsStartNo', 24, ...
                'PrbData', [], ...
                'RRsep', [], ...
                'EfitInterpNo', 2);
            Args = parseArgs(varargin, Args, {'MsParallel', 'ZeroBg'});
            port_name = Args.PortName;
            time_range = Args.TimeRange;
            interp_no = Args.EfitInterpNo;
            fit_cfg = {'TimeSlices', Args.TimeSlices, ...
                    'AvgTime', Args.AvgTime, ...
                    'ZeroBg', Args.ZeroBg, ...
                    'MsParallel', Args.MsParallel, ...
                    'MsStartNo', Args.MsStartNo};
            %% check time_range
            if isempty(time_range)
                ip = proc_ip(shotno);
                if ~ip.status
                    error('invalid shot!')
                end
                time_range = ip.flat_time;
            end
            %% check cmb
            if isempty(port_name)
                pb = prbbase(shotno, position_tag);
                port_list = pb.prb_list_portnames;
                if length(port_list) == 1
                    cmb = 0;
                else
                    cmb = 1;
                end
                port_name = port_list{1};
            else
                if ischar(port_name)
                    cmb = 0;
                elseif iscell(port_name) && length(port_name) > 1
                    port_list = port_name;
                    cmb = 1;
                    port_name = port_list{1};
                else
                    error('port_name not valid!')
                end
            end
            %% load prbdata in the first place
            if isempty(Args.PrbData)
                pda = prbdata(shotno, position_tag, port_name);
                has_prbdata = 0;
            else
                if cmb
                    pda = Args.PrbData{1};
                else
                    pda = Args.PrbData;
                end
                has_prbdata = 1;
            end
            pda.load(phy_type, time_range);
            %% load RRsep in the first place
            if isempty(Args.RRsep)
                efit_info = prbfit.gen_efitinfo(pda.(phy_type));
                efit_info = prbfit.interp_efitinfo(efit_info, interp_no);
                rrsep = prbfit.gen_rrsep(pda.(phy_type), efit_info);
                has_rrsep = 0;
            else
                rrsep = Args.RRsep;
                has_rrsep = 1;
            end
            %% cmb==0
            if cmb == 0
                fits_res = prbfit.fits(pda.(phy_type), rrsep, fit_cfg{:});
                pda_out = pda;
                rrsep_out = rrsep;
                return
            end
            %% cmb==1
            pda_rz = pda.(phy_type).prb_extract_distinfo('rz');
            pda_out = {pda};
            pda_list = {pda.(phy_type)};
            rrsep_list = {rrsep};
            for i=2:length(port_list)
                port_name = port_list{i};
                if has_prbdata
                    pda = Args.PrbData{i};
                else
                    pda = prbdata(shotno, position_tag, port_name);
                end
                pda.load(phy_type, time_range);
                pda_out{end+1} = pda;
                pda_list{end+1} = pda.(phy_type);
                if has_rrsep
                    continue
                end
                if sum(sum(pda_rz - pda.(phy_type).prb_extract_distinfo('rz'))) == 0
                    rrsep_list{end+1} = rrsep;
                    rrsep_list{end}.port_name = port_name;
                else
                    efit_info = prbfit.gen_efitinfo(pda.(phy_type));
                    efit_info = prbfit.interp_efitinfo(efit_info, interp_no);
                    rrsep = prbfit.gen_rrsep(pda.(phy_type), efit_info);
                    rrsep_list{end+1} = rrsep;
                end
            end
            if has_rrsep
                rrsep_list = Args.RRsep;
            end
            fits_res = prbfit.fits(pda_list, rrsep_list, fit_cfg{:});
            rrsep_out = rrsep_list;
        end
                
        function res = fits_extract(fits_res, field_name)
            if fieldexist(fits_res, 'fits')
                fits = fits_res.fits;
            elseif fieldexist(fits_res,'fit_res')
                fits = fits_res;
            else
                error('Unrecognized input!')
            end
            
            res = [];
            if haselement({'peak','lam','S','r0','bg','r2'}, field_name)
                for i=1:length(fits)
                    res(end+1) = fits(i).fit_res.(field_name);
                end
                return
            end
            if isequal(field_name, 'time')
                res = [fits.time];
                return
            end
            if haselement({'ymin','ymax'}, field_name)
                for i=1:length(fits)
                    res(end+1) = fits(i).fit_data.(field_name)(1);
                end
                return
            end
        end
        
        function fig = fits_view(fits_res, varargin)
            %% check arguments
            Args.R2Min = 0.88;
            Args.LineSpec = 'ks-';
            Args.LineWidth = 2;
            Args.MarkerSize = 8;
            Args.FontSize = 20;
            Args.Figure = [];
            Args.ShowYLabel = 1;
            Args = parseArgs(varargin, Args);
            %% recursive call
            if iscell(fits_res) && length(fits_res) > 1
                Args.LineSpec = 's-';
                varargin = struct2vararg(Args);
                fig = prbfit.fits_view(fits_res{1}, varargin{:});
                fnames = {'position_tag', 'port_name', 'phy_type'};
                legend_strs{1} = num2str(fits_res{1}.shotno); 
                x_lims = xlim';
                Args.ShowYLabel = 0;
                Args.Figure = fig;
                varargin = struct2vararg(Args);
                for i=2:length(fits_res)
                    for j=1:length(fnames)
                        if ~isequal(fits_res{1}.(fnames{j}), fits_res{i}.(fnames{j}))
                            error(['"' fnames{j} '" is not the same!'])
                        end
                    end
                    fig = prbfit.fits_view(fits_res{i}, varargin{:});
                    legend_strs{i} = num2str(fits_res{i}.shotno);
                    x_lims(:,end+1) = xlim;
                end
                samexaxis('join','yal', 'alt2','xlim',[max(x_lims(1,:)) min(x_lims(2,:))]);
                axislist = getsubplots(fig);
                for i=1:length(axislist)
                    subplot(axislist(i))
                    legend(legend_strs, 'Orientation', 'horizontal', 'Location', 'best')
                    if i==1
                        title(['Div-LP ' upper(fits_res{1}.position_tag) '-' upper(strjoin(fits_res{1}.port_name,'&'))]);
                    end
                end
                return
            end
            %% extract data
            time = prbfit.fits_extract(fits_res, 'time');
            lam  = prbfit.fits_extract(fits_res, 'lam');
            S    = prbfit.fits_extract(fits_res, 'S');
            r2   = prbfit.fits_extract(fits_res, 'r2');
            ymax = prbfit.fits_extract(fits_res, 'ymax');
            inds = r2 >= Args.R2Min;
            lamint = [];
            for i=1:length(time)
                if ~inds(i)
                    continue
                end
                fit_data = fits_res.fits(i).fit_data; 
                fit_res  = fits_res.fits(i).fit_res; 
                lamint(end+1) = prbfit.cal_lambda_int(fit_data, fit_res, 'type', 'eich');
            end
            phy_type_latex = prbbase.prb_get_phytype(fits_res.phy_type);
            phy_type = lower(strrmsymbol(fits_res.phy_type));
            if strcmpi(phy_type, 'qpar')
                phy_type_latex = 'q_{//}';
                phy_type = 'q';
            end
            %% plot
            x = time(inds);
            if isempty(x)
                return
            end
            ylist = {lam(inds), S(inds), lamint, r2(inds), ymax(inds)};
            ylabel_list = {...
                ['a) \lambda_{' phy_type '} [mm]'],...
                ['b) S_{' phy_type '} [mm]'],...
                ['c) \lambda_{' phy_type ',int} [mm]'],...
                'd) R^2',...
                ['e) ' phy_type_latex '_{,peak}']};
            if isempty(Args.Figure)
                fig = figure(gcf);
            else
                fig = figure(Args.Figure);
                axislist = getsubplots;
            end
            for i=1:length(ylist)
                if isempty(Args.Figure)
                    subplot(5,1,i)
                else
                    subplot(axislist(i))
                end
                hold on
                plot(x, ylist{i},  Args.LineSpec, 'linewidth', Args.LineWidth, 'markersize', Args.MarkerSize);
                hold off
                set(gca, 'fontsize', Args.FontSize);
                if i==1
                    title(['#' num2str(fits_res.shotno) ' ' upper(fits_res.position_tag) '-' upper(strjoin(fits_res.port_name,'&'))])
                end
                if Args.ShowYLabel
                    text(0.05, 0.75, ylabel_list{i}, 'unit', 'normalized', 'color', 'r', 'fontsize', Args.FontSize);
                end
            end
            samexaxis('join','yal', 'alt2');
            xlabel('Time [s]')
            xlim([min(x) max(x)])
            set(gcf, 'color', 'w');
            setfigpostion('left');
        end
        
        function fig = fits_profile(fits_res, t)
            time = prbfit.fits_extract(fits_res, 'time');
            tind = findvalue(time, t);
            fit_data = fits_res.fits(tind).fit_data;
            fit_res  = fits_res.fits(tind).fit_res;
            fig = prbfit.fitdata_plot(fit_data, fit_res);
            title(['#' num2str(fits_res.shotno) '@' num2str(t,'%3.2f') 's ' upper(fits_res.position_tag) '-' upper(strjoin(fits_res.port_name,'&'))])
        end
        
        function fig = fits_profile_all(fits_res, time_range, subfigno)
            time = prbfit.fits_extract(fits_res, 'time');
            if nargin < 3
                subfigno = 20;
            end
            if nargin < 2
                time_range = time([1 end]);
                subfigno = 20;
            end
            time_inds = findtime(time, time_range);
            time = time(time_inds(1):time_inds(2));
            time_len = length(time);
            if time_len < subfigno
                subfigno =  time_len;
                inds = 1:time_len;
            else
                inds = round(linspace(1,length(time), subfigno));
            end

            row_no = floor(sqrt(subfigno));
            col_no = ceil(subfigno/row_no);
            h = 0.95/row_no;
            w = 0.95/col_no;
            fig = figure;
            setfigpostion
            for i=1:length(inds)
                r = floor((i-1)/col_no)+1;
                c = i-(r-1)*col_no;
                l = 0.025+(c-1)*w;
                b = 0.04+(row_no-r)*h;
                ax = subplot(row_no, col_no, i);
                set(ax, 'position', [l, b, w*0.98, h*0.98]);
                t = time(inds(i));
                prbfit.fits_profile(fits_res, t);
                axes = get(gca,'children');
                str_r2 = axes(1).String{3};
                delete(axes(1));
                xlabel([]);
                ylabel([]);
                title([]);
                xticks([]);
                yticks([]);
                str = {num2str(t, 't=%.2fs')};
                str{end+1} = strrep(str_r2, ' ','');
                textbp(str,'fontsize',15,'color','r');
            end
        end
    end
end