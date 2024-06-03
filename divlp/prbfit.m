%% Fitting class of lambda for divlp
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2019-08-30
classdef prbfit
    methods(Static)
        function efit_info = gen_efitinfo(prbd, efit_tree)
            %% check arguments
            if ~isa(prbd, 'prbdataraw') && ~isa(prbd, 'prbdatacal')
                error('prbd should be prbdataraw or prbdatacal type!')
            end
            if nargin < 2
                efit_tree = 'efit_east';
            end
            %% gen efit info
            shotno = prbd.shotno;
            efit_info = efit_map(shotno, prbd.prb_extract_distinfo('rz'), 1, [], 0, efit_tree);
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
        
        function xthres = cal_xthres(xdata, divide_factor)
            if nargin < 2
                divide_factor = 10;
            end
            x_diff = diff(unique(xdata));
            loop_no = ceil(length(x_diff)*.1);
            for i=1:loop_no
                [x_diff_max, ind] = max(x_diff);
                x_diff(ind) = [];
            end
            xthres = x_diff_max/divide_factor;
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
            fit_data.chtot = size(prbd.data, 1);
            fit_data.chtot_valid = fit_data.chtot - sum(isnan(prbd.data(:,1)));
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
        
        % to do find a method to cal fit_data.chtot and fit_data.chtot_avg
        function fit_data = fitdata_combine(fit_data_list, method)
            %% check arguments
            if ~iscell(fit_data_list) && length(fit_data_list) < 2
                error('fit_data_list should have at least two elements!')
            end
            assert(haselement({'weighted', 'normal', 'concat'}, lower(method)), 'Combining method should be in {"weighted", "normal", "concat"}!');
            %% concatenate
            fit_data = fit_data_list{1};
            has_yerr = fieldexist(fit_data, 'yerr');
            if strcmpi(method, 'concat')
                for i=2:length(fit_data_list)
                    if ~isequal(fit_data.xtype, fit_data_list{i}.xtype)
                        error('xtype not match!')
                    end
                    if ~isequal(fit_data.ytype, fit_data_list{i}.ytype)
                        error('ytype not match!')
                    end
                    fit_data.xdata = [fit_data.xdata fit_data_list{i}.xdata];
                    fit_data.ydata = [fit_data.ydata fit_data_list{i}.ydata];
                    if has_yerr
                        fit_data.yerr = [fit_data.yerr fit_data_list{i}.yerr];
                    end
                end
                return
            end
            %% weighted averaging
            if strcmpi(method, 'weighted') && ~has_yerr
                for i=1:length(fit_data_list)
                    xthres = prbfit.cal_xthres(fit_data_list{i}.xdata);
                    fit_data_list{i} = prbfit.fitdata_avg(fit_data_list{i}, 'xthres', xthres);
                end
            end
            %% normal avraging            
            fit_data = prbfit.fitdata_combine(fit_data_list, 'concat');
            xthres = prbfit.cal_xthres(fit_data.xdata, 8);
            fit_data = prbfit.fitdata_avg(fit_data, 'xthres', xthres);
        end
        
        function fit_data = fitdata_avg(fit_data, varargin)
            %% check arguments
            Args.UseMedian = 1;
            Args.XThres = 0;
            Args = parseArgs(varargin, Args, {'UseMedian'});
            len = length(fit_data.xdata);
            assert(length(fit_data.ydata)==len,'xdata and ydata should have the same length!')
            has_yerr = fieldexist(fit_data, 'yerr');
            avg_samex = Args.XThres == 0;
            if has_yerr
                avg_samex = 0;
            end
            if ~avg_samex && Args.XThres == 0
                Args.XThres = prbfit.cal_xthres(fit_data.xdata, 50);
            end
            %% set funs
            if Args.UseMedian
                fun_avg = @median;
                fun_err = @mad;
            else
                fun_avg = @mean;
                fun_err = @std;
            end
            %% average by the same x
            xdata = [];
            ydata = [];
            yerr = [];
            if avg_samex
                xdata = sort(unique(fit_data.xdata)); %% sorted automatically
                for i=1:length(xdata)
                    inds = fit_data.xdata==xdata(i);
                    y = fit_data.ydata(inds);
                    ydata(end+1) = fun_avg(y);
                    yerr(end+1)  = fun_err(y);
                end
            %% average by the adjacent x
            else
                %% sort data
                if sum(diff(fit_data.xdata)<0)
                    [fit_data.xdata, sort_inds] = sort(fit_data.xdata);
                    fit_data.ydata = fit_data.ydata(sort_inds);
                    if has_yerr
                        fit_data.yerr  = fit_data.yerr(sort_inds);
                    end
                end
                %% get inds for adjacent points            
                inds_list = {};
                ind_start = 1;
                for i=2:len
                    if fit_data.xdata(i) - fit_data.xdata(ind_start) > Args.XThres
                        inds_list{end+1} = ind_start:i-1;
                        ind_start = i;
                    end
                end
                inds_list{end+1} = ind_start:len;
                %% average by inds
                for i=1:length(inds_list)
                    inds = inds_list{i};
                    if ~has_yerr
                        x = fit_data.xdata(inds);
                        y = fit_data.ydata(inds);
                        xdata(end+1) = fun_avg(x);
                        ydata(end+1) = fun_avg(y);
                        yerr(end+1)  = fun_err(y);
                        continue
                    end
                    
                    inds = inds(fit_data.yerr(inds) > 0);
                    if isempty(inds)
                        continue
                    end
                    
                    x  = fit_data.xdata(inds);
                    y  = fit_data.ydata(inds);
                    ye = fit_data.yerr(inds);
                    w  = y./ye; w = w./sum(w);

                    xdata(end+1) = mean(x);
                    ydata(end+1) = sum(y.*w);
                    yerr(end+1)  = sqrt(sum((ye.*w).^2));
                end
            end
            len = length(xdata);
            if length(ydata) ~= len || length(yerr) ~= len
                error('ydata or yerr has different length with xdata!')
            end
            if sum(isnan(ydata) | isnan(xdata) | isnan(yerr))
                error('NaN inside!')
            end
            fit_data.xdata = xdata;
            fit_data.ydata = ydata;
            fit_data.yerr  = yerr;
            %% set ymin & ymax
%             [fit_data.ymin, ind] = min(fit_data.ydata);
%             fit_data.ymin(2) = fit_data.yerr(ind);
%             [fit_data.ymax, ind] = max(fit_data.ydata);
%             fit_data.ymax(2) = fit_data.yerr(ind);
            [fit_data.ymin, ind] = min(fit_data.ydata);
            fit_data.ymin(2) = fit_data.yerr(ind);
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
                        c.r0 = coeff(4); % fitted LCFS
                        c.bg = coeff(5); % fitted background
                    otherwise
                        error('The length of coeff should be 3, 4 or 5!')
                end
                c.amp = coeff(1); % amplitude on OMP
                c.lam  = coeff(2); % e-folding length on OMP
                c.S    = coeff(3); % spreading factor mapped to OMP
                if nargin == 1
                    ydata = [];
                    return
                end
            elseif isstruct(coeff)
                c = coeff;
            else
                error('Unsupport coeff type!')
            end
            ydata = c.amp/2*exp((c.S/2/c.lam)^2 - (xdata - c.r0)/c.lam).*erfc(c.S/2/c.lam - (xdata - c.r0)/c.S) + c.bg;
        end
        
        function fit_res = eichfit(fit_data, varargin)
            %% check arguments
            if ~fieldexist(fit_data, 'xdata') || ~fieldexist(fit_data, 'ydata')
                error('fit_data is has no xdata or ydata field!')
            end
            Args = struct(...
                'ZeroBg', 0, ...
                'MsParallel', 0, ...
                'MsStartNo', 4, ...
                'FitBdry', [1000 100 100 50 100; 0 0 0 -50 -100]);
            Args = parseArgs(varargin, Args, {'MsParallel', 'ZeroBg'});
            assert(sum(isnan(fit_data.ydata) | isnan(fit_data.xdata)) == 0, 'fit_data has NaN inside!');
            %% set fit boundary
            ub = Args.FitBdry(1,:);
            lb = Args.FitBdry(2,:);
            num_fit_vars = 5;
            if Args.ZeroBg
                ub(5) = 0; lb(5) = 0;
                num_fit_vars = 4;
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
            fit_res.chi2 = prbfit.chi_squared(fit_data, fit_res, num_fit_vars);
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
        
        function fig = fitdata_plot(fit_data, fit_res, varargin)
            %% check arguments
            Args.SameColor = 0;
            Args.ShowR0 = 0;
            Args.NoError = ~fieldexist(fit_data, 'yerr');
            Args.LineSpecData = 'k*';
            Args.LineSpecFit = 'r';
            Args.LineSpecSep = 'k:';
            Args.TextColor = 'r';
            Args.MarkerSize = 8;
            Args.LineWidth = 2;
            Args.FontSize = 20;
            Args = parseArgs(varargin, Args, {'SameColor', 'ShowR0', 'NoError'});
            %% plot fit_data
            fig = figure(gcf);
            if Args.NoError 
                plot(fit_data.xdata, fit_data.ydata, Args.LineSpecData, 'linewidth', Args.LineWidth, 'markersize', Args.MarkerSize);
            else
                errorbar(fit_data.xdata, fit_data.ydata, fit_data.yerr, Args.LineSpecData, 'linewidth', Args.LineWidth, 'markersize', Args.MarkerSize);
            end
            if Args.SameColor
                h = get(gca,'children');
                color = h(1).Color;
            end
            set(gcf, 'color', 'w');
            set(gca, 'fontsize', Args.FontSize);
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
            x_lim = [min(fit_data.xdata) max(fit_data.xdata)];
            x_lim = x_lim + [-1 1]*diff(x_lim)*.05;
            xlim(x_lim);
            if ~Args.NoError
                y_lim = [min(fit_data.ydata -fit_data.yerr) max(fit_data.ydata+fit_data.yerr)];
                y_lim = y_lim + [-1 1]*diff(y_lim)*.05;
                ylim(y_lim);
            end
            if nargin == 1
                return
            end
            %% plot fit_res
            hold on
            x = linspace(min(fit_data.xdata), max(fit_data.xdata), 100);
            y = prbfit.fun_eich(fit_res, x);
            h = plot(x,y,Args.LineSpecFit,'linewidth', Args.LineWidth*1.25);
            if Args.SameColor
                set(h, 'color', color);
            end
            %% plot r0
            h = vline(fit_res.r0, Args.LineSpecSep);
            set(h, 'linewidth', Args.LineWidth);
            if Args.SameColor
                set(h, 'color', color);
            end
            hold off
            %% disp fitting results
            lam_int = prbfit.cal_lambda_int(fit_data, fit_res);
            fitres_str = {['\lambda = ' num2str(fit_res.lam,'%3.2f') ' [mm]']};
            fitres_str{end+1} = ['S = ' num2str(fit_res.S,'%3.2f') ' [mm]'];
            fitres_str{end+1} = ['\lambda_{int} = ' num2str(lam_int,'%3.2f') ' [mm]'];
            fitres_str{end+1} = ['\chi^2 = ' num2str(prbfit.chi_squared(fit_data, fit_res), '%3.2f')];
            fitres_str{end+1} = ['R^2 = ' num2str(fit_res.r2,'%1.2f')];
            fitres_str{end+1} = num2str(fit_res.r0, 'r0 = %3.2f [mm]');
            h = text(diff(xlim)*0.05+min(xlim),diff(ylim)*0.75+min(ylim), ...
                fitres_str, 'fontsize', Args.FontSize, 'color', Args.TextColor);
            if Args.SameColor
                set(h, 'color', color);
            end
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
                if abs(f - s - time_slice_len) < 1.001*dt
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
                'MsStartNo', 4, ...
                'FitBdry', [1000 100 100 50 100; 0 0 0 -50 -100], ...
                'AvgTime', 0.05, ...
                'TimeSlices', [],...
                'CombineMethod', 'weighted');
            Args = parseArgs(varargin, Args, {'ZeroBg', 'MsParallel'});
            assert(haselement({'normal', 'weighted'}, Args.CombineMethod), 'Unrecognized Combine Method, should be "normal" or "weighted"!');
            fit_cfg = {...
                    'ZeroBg', Args.ZeroBg, ...
                    'MsParallel', Args.MsParallel, ...
                    'MsStartNo', Args.MsStartNo,...
                    'FitBdry', Args.FitBdry};
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
%             disp_inds = linspace(1, length(time_slices), 10);
%             disp_inds = unique(round(disp_inds));
            dispstat('','init');
            for i=1:length(time_slices)
                time_slice = time_slices{i};
                if cmb % use fitdata_combine by default
                    prbd_len = length(prbd);
                    fit_data_list = cell(1, prbd_len);
                    for j=1:length(prbd)
                        fit_data_list{j} = prbfit.fitdata_gen(prbd{j}, xaxis{j}, time_slice);
                    end
                    fit_data = prbfit.fitdata_combine(fit_data_list, Args.CombineMethod);
                    if length(xaxis) == 2 && isequal(xaxis{1}.data, xaxis{2}.data)
                        s1 = prbd{1}.sigslice(time_slice);
                        s2 = prbd{2}.sigslice(time_slice);
                        d1 = mean(s1.data, 2);
                        d2 = mean(s2.data, 2);
                        fit_data.merge_r2 = rsquare(d1, d2);
                    end                
                else % use fitdata_avg with samex by default
                    fit_data = prbfit.fitdata_gen(prbd, xaxis, time_slice);
                    fit_data = prbfit.fitdata_avg(fit_data);
                end
                fits(i).time     = mean(time_slice);
                fits(i).fit_data = fit_data;
                fits(i).fit_res  = prbfit.eichfit(fit_data, fit_cfg{:});
%                 if sum(disp_inds == i)
                    dispstat(['fitting progress: ' num2str(100*i/slice_no,'%5.1f') '%']);
%                 end
            end
            dispstat('','clean');
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
                'CombineMethod', 'weighted',...
                'ZeroBg', 0, ...
                'MsParallel', 0, ...
                'MsStartNo', 4, ...
                'PrbData', [], ...
                'RRsep', [], ...
                'EfitInterpNo', 2);
            Args = parseArgs(varargin, Args, {'MsParallel', 'ZeroBg'});
            port_name = Args.PortName;
            time_range = Args.TimeRange;
            interp_no = Args.EfitInterpNo;
            fit_cfg = {'TimeSlices', Args.TimeSlices, ...
                    'AvgTime', Args.AvgTime, ...
                    'CombineMethod', Args.CombineMethod,...
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
            if length(fits) < 1
                return
            end
            if haselement({'amp','lam','S','r0','bg','r2'}, field_name)
                if ~fieldexist(fits(1).fit_res, field_name)
                    return
                end
                for i=1:length(fits)
                    res(end+1) = fits(i).fit_res.(field_name);
                end
                return
            end
            if haselement({'chi2', 'chi_squared'}, field_name)
                if fieldexist(fits(1).fit_res, 'chi2')
                    for i=1:length(fits)
                        res(end+1) = fits(i).fit_res.chi2;
                    end
                    return
                end
                
                for i=1:length(fits)
                    fit_data = fits(i).fit_data;
                    fit_res = fits(i).fit_res;
                    res(end+1) = prbfit.chi_squared(fit_data, fit_res);
                end
            end
            if isequal(field_name, 'time')
                res = [fits.time];
                return
            end
            if haselement({'ymin','ymax', 'merge_r2'}, field_name)
                if ~fieldexist(fits(1).fit_data, field_name)
                    return
                end
                for i=1:length(fits)
                    res(end+1) = fits(i).fit_data.(field_name)(1);
                end
                return
            end
            if haselement({'lamintraw', 'laminteich'}, field_name)
                for i=1:length(fits)
                    res(i) = prbfit.cal_lambda_int(fits(i).fit_data, fits(i).fit_res, 'type', field_name(7:end));
                end
                return
            end
        end
        
        function chi2 = chi_squared(fit_data, fit_res, num_fit_vars)
            if nargin == 2
                num_fit_vars = 5;
                if fit_res.bg == 0
                    num_fit_vars = 4;
                end
            end
            
            chi2 = chi_squared(...
                fit_data.ydata,...
                prbfit.fun_eich(fit_res, fit_data.xdata), ...
                num_fit_vars);
        end
        
        function [fits_bit, fnames] = fits_bit(fits_res1, fits_res2)
            fnames = {'shotno', 'position_tag', 'port_name', 'phy_type'};
            fits_bit = false(1, length(fnames));
            for i=1:length(fnames)
                fits_bit(i) = isequal(fits_res1.(fnames{i}), fits_res2.(fnames{i}));
            end
        end
        
        function fig = fits_view(fits_res, varargin)
            %% check arguments
            Args.R2Min = 0.88;
            Args.INDS = [];
            Args.LineSpec = 'ks-';
            Args.LineWidth = 2;
            Args.MarkerSize = 8;
            Args.FontSize = 20;
            Args.Figure = [];
            Args.ShowYLabel = 1;
            Args.PlotMergeR2 = 1;
            Args.PlotFitAmp = 1;
            Args.PlotFitR0 = 1;
            Args.PlotFitBg = 1;
            Args.PlotSimple = 0;
            Args = parseArgs(varargin, Args, {'ShowYLabel', 'PlotMergeR2', 'PlotFitAmp', 'PlotFitR0', 'PlotFitBg', 'PlotSimple'});
            
            fig = [];
            
            if Args.PlotSimple
                Args.PlotFitAmp = 0;
                Args.PlotFitR0 = 0;
                Args.PlotFitBg = 0;
            end
            %% recursive call
            if iscell(fits_res) && length(fits_res) > 1
                %% plot first element
                Args.LineSpec = 's-';
                varargin = struct2vararg(Args);
                fig = prbfit.fits_view(fits_res{1}, varargin{:});
                x_lims = xlim';
                [fits_bit, fnames] = prbfit.fits_bit(fits_res{1}, fits_res{2}); 
                if ~fits_bit(4)
                    error('phy_type is not the same!')
                end
                if sum(fits_bit(1:3)) ~= 2
                    error('{"shotno", "position_tag", "port_name"} can only allow one element be different!')
                end
                ind = findvalue(fits_bit, false);
                val = fits_res{1}.(fnames{ind});
                if isnumeric(val); val = num2str(val); end
                if iscell(val); val = strjoin(val,''); end
                legend_strs{1} = val;
                portname_tag = upper(strjoin(fits_res{1}.port_name,'&'));
                if ~isempty(portname_tag)
                    portname_tag = ['[' portname_tag  ']'];
                end
                tit = {...
                    num2str(fits_res{1}.shotno, '#%i'),...
                    upper(fits_res{1}.position_tag),...
                    portname_tag};
                tit = tit(fits_bit(1:3));
                tit = strjoin(tit, ' ');
                %% plot the rest
                Args.ShowYLabel = 0;
                Args.Figure = fig;
                varargin = struct2vararg(Args);
                for i=2:length(fits_res)
                    if ~isequal(fits_bit, prbfit.fits_bit(fits_res{1}, fits_res{i}))
                        error(['fits_bit is not the same for the ' num2str(i) ' element!'])
                    end
                    fig = prbfit.fits_view(fits_res{i}, varargin{:});
                    val = fits_res{i}.(fnames{ind});
                    if isnumeric(val); val = num2str(val); end
                    if iscell(val); val = strjoin(val,''); end
                    if ~isempty(fig)
                        legend_strs{end+1} = val;
                    end
                    x_lims(:,end+1) = xlim;
                end
                if length(getsubplots) > 1
                    samexaxis('join','yal', 'alt2','xlim',[max(x_lims(1,:)) min(x_lims(2,:))]);
                end
                axislist = getsubplots(fig);
%                 for i=1:length(axislist)
%                     subplot(axislist(i))
%                     legend(legend_strs, 'Orientation', 'horizontal', 'Location', 'best')
%                     if i==1
%                         title(['Div-LP ' tit]);
%                     end
%                 end
                if length(axislist) >= 1
                    subplot(axislist(1));
                    title(['Div-LP ' tit]);
                end
                legend(legend_strs, 'Orientation', 'horizontal', 'Location', 'best');
                return
            end
            %% extract data
            time = prbfit.fits_extract(fits_res, 'time');
            if isempty(time)
                return
            end
            lam  = prbfit.fits_extract(fits_res, 'lam');
            S    = prbfit.fits_extract(fits_res, 'S');
            r2   = prbfit.fits_extract(fits_res, 'r2');
            ymax = prbfit.fits_extract(fits_res, 'ymax');
            merge_r2 = prbfit.fits_extract(fits_res, 'merge_r2');
            amp  = prbfit.fits_extract(fits_res, 'amp');
            r0   = prbfit.fits_extract(fits_res, 'r0');
            bg   = prbfit.fits_extract(fits_res, 'bg');
            inds = r2 >= Args.R2Min;
            if ~isempty(Args.INDS)
                assert(length(Args.INDS) == length(time), 'argument INDS has different length with fits_res.fits!');
                inds = Args.INDS;
            end
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
            if length(x) < 3
                return
            end
            ylist = {lam(inds), S(inds), lamint, r2(inds), ymax(inds)};
            ylabel_list = {...
                ['a) \lambda_{' phy_type '} [mm]'],...
                ['b) S_{' phy_type '} [mm]'],...
                ['c) \lambda_{' phy_type ',int} [mm]'],...
                'd) R^2_{fit}',...
                ['e) ' phy_type_latex '_{,peak}']};
            fig_indices = {'f)', 'g)', 'h)', 'i)'};
            fig_indices_pnt = 0;
            if Args.PlotMergeR2 && ~isempty(merge_r2)
                ylist{end+1} = merge_r2(inds);
                fig_indices_pnt = fig_indices_pnt +1;
                ylabel_list{end+1} = [fig_indices{fig_indices_pnt} ' R^2_{merge}'];
            end
            if Args.PlotFitAmp && ~isempty(amp)
                ylist{end+1} = amp(inds);
                fig_indices_pnt = fig_indices_pnt +1;
                ylabel_list{end+1} = [fig_indices{fig_indices_pnt} ' ' phy_type_latex '_{,fit,amp}'];
            end
            if Args.PlotFitR0 && ~isempty(r0)
                ylist{end+1} = r0(inds);
                fig_indices_pnt = fig_indices_pnt +1;
                ylabel_list{end+1} = [fig_indices{fig_indices_pnt} ' ' phy_type_latex '_{,fit,r0}'];
            end
            if Args.PlotFitBg && ~isempty(bg)
                ylist{end+1} = bg(inds);
                fig_indices_pnt = fig_indices_pnt +1;
                ylabel_list{end+1} = [fig_indices{fig_indices_pnt} ' ' phy_type_latex '_{,fit,bg}'];
            end
            if isempty(Args.Figure)
                fig = figure(gcf);
            else
                fig = figure(Args.Figure);
                axislist = getsubplots;
            end
            ylist_len = length(ylist);
            for i=1:ylist_len
                if isempty(Args.Figure)
                    subplot(ylist_len,1,i)
                else
                    subplot(axislist(i))
                end
                hold on
                plot(x, ylist{i},  Args.LineSpec, 'linewidth', Args.LineWidth, 'markersize', Args.MarkerSize);
                hold off
                set(gca, 'fontsize', Args.FontSize);
                if i==1
                    tit = ['#' num2str(fits_res.shotno) ' ' upper(fits_res.position_tag)];
                    portname_tag = upper(strjoin(fits_res.port_name,'&'));
                    if ~isempty(portname_tag)
                        tit = [tit '-' portname_tag];
                    end
                    title(tit)
                end
                if Args.ShowYLabel
                    text(0.05, 0.75, ylabel_list{i}, 'unit', 'normalized', 'color', 'r', 'fontsize', Args.FontSize);
                end
            end
            samexaxis('join','yal', 'alt2');
            xlabel('Time [s]')
            xlim([min(x) max(x)])
            set(gcf, 'color', 'w');
            setfigposition('left');
        end
        
        function fig = fits_profile(fits_res, t, varargin)
            %% recursive call
            len_f = length(fits_res);
            len_t = length(t);
            if len_f == len_t && len_f > 1 || len_f == 1 && len_t > 1 || len_f > 1 && len_t == 1
                flag_sc = 0;
                flag_lsd = 0;
                for i=1:length(varargin)
                    if flag_sc && flag_lsd
                        break
                    end
                    if ischar(varargin{i}) 
                        if ~flag_sc && ( strcmpi(varargin{i}, 'samecolor') || strcmpi(varargin{i}, 'sc') )
                            flag_sc = 1;
                            continue
                        end
                        if ~flag_lsd && ( strcmpi(varargin{i}, 'linespecdata') || strcmpi(varargin{i}, 'lsd') )
                            varargin{i+1} = varargin{i+1}(end);
                            flag_lsd = 1;
                            continue
                        end
                    end
                end
                if ~flag_sc
                    varargin{end+1} = 'SameColor';
                end
                if ~flag_lsd
                    varargin{end+1} = 'LineSpecData';
                    varargin{end+1} = '*';
                end
                
                fig = figure(gcf);
                setfigposition
                legend_str = {};
                y_lims = [];
                
                if len_f == len_t && len_f > 1
                    for i=1:length(fits_res)
                        figure(fig);
                        prbfit.fits_profile(fits_res{i}, t(i), varargin{:});
                        legend_str{end+1} = ['#' num2str(fits_res{i}.shotno) ' ' upper(fits_res{i}.position_tag) '-' upper(strjoin(fits_res{i}.port_name,'&')) num2str(t(i), '@%3.2fs')];
                        legend_str{end+1} = 'Fit';
                        hold on
                        y_lims = [y_lims; ylim];
                    end
                    tit_str = ['DivLP ' lower(fits_res{i}.phy_type)];
                end
                
                if length(fits_res) == 1
                    for i=1:length(t)
                        figure(fig);
                        prbfit.fits_profile(fits_res, t(i), varargin{:});
                        legend_str{end+1} = num2str(t(i), 't=%3.2fs');
                        legend_str{end+1} = 'Fit';
                        hold on
                        y_lims = [y_lims; ylim];
                    end
                    tit_str = ['#' num2str(fits_res.shotno) ' DivLP ' upper(fits_res.position_tag) '-' upper(strjoin(fits_res.port_name,'&'))];
                end
                
                if length(t) == 1
                    for i=1:length(fits_res)
                        figure(fig);
                        prbfit.fits_profile(fits_res{i}, t, varargin{:});
                        legend_str{end+1} = ['#' num2str(fits_res{i}.shotno) ' ' upper(fits_res{i}.position_tag) '-' upper(strjoin(fits_res{i}.port_name,'&'))];
                        legend_str{end+1} = 'Fit';
                        hold on
                        y_lims = [y_lims; ylim];
                    end
                    tit_str = num2str(t,'DivLP t=%3.2fs');
                end
                
                title(tit_str)
                legend(legend_str);
                ylim([min(y_lims(:,1)) max(y_lims(:,2))])
                return
            end
            %% single call
            Args.ShowChannelNo = 0;
            Args.SameColor = 0;
            Args.ShowR0 = 0;
            Args.LineSpecData = 'k*';
            Args.LineSpecFit = 'r';
            Args.LineSpecSep = 'k:';
            Args.TextColor = 'r';
            Args.MarkerSize = 8;
            Args.LineWidth = 2;
            Args.FontSize = 20;
            Args = parseArgs(varargin, Args, {'ShowChannelNo', 'SameColor', 'ShowR0'});
            show_channel_no = Args.ShowChannelNo;
            Args = rmfield(Args, 'ShowChannelNo');
            varargin = struct2vararg(Args);
            
            time = prbfit.fits_extract(fits_res, 'time');
            tind = findvalue(time, t);
            fit_data = fits_res.fits(tind).fit_data;
            fit_res  = fits_res.fits(tind).fit_res;
            fig = prbfit.fitdata_plot(fit_data, fit_res, varargin{:});
            title(['#' num2str(fits_res.shotno) '@' num2str(t,'%3.2f') 's ' upper(fits_res.position_tag) '-' upper(strjoin(fits_res.port_name,'&'))])
            
            if show_channel_no && strcmpi(fit_data.xtype, 'dist2div')
                pb = prbbase(fits_res.shotno, fits_res.position_tag, fits_res.port_name{1});
                pb.prb_load_sys;
                ch = pb.prb_extract_distinfo('channel');
                if min(ch)>length(ch); ch = ch - length(ch); end
                x = pb.prb_extract_distinfo(fit_data.xtype); x = abs(x);
                y = prbfit.fun_eich(fit_res,x);
                for i=1:length(ch); text(x(i),y(i)-diff(ylim)*0.06,num2str(ch(i)),'color','r','fontsize',10); end
            end
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
            if isempty(time_range)
                time_range = time([1 end]);
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
            setfigposition
            for i=1:length(inds)
                r = floor((i-1)/col_no)+1;
                c = i-(r-1)*col_no;
                l = 0.025+(c-1)*w;
                b = 0.04+(row_no-r)*h;
                ax = subplot(row_no, col_no, i);
                set(ax, 'position', [l, b, w*0.98, h*0.98]);
                t = time(inds(i));
                prbfit.fits_profile(fits_res, t, 'LineSpecSep', 'r:');
                axes = get(gca,'children');
                str_lam = strrep(axes(1).String{1}(1:end-4), '=',':');
                str_s   = strrep(axes(1).String{2}(1:end-4), '=',':');
                str_r2  = strrep(axes(1).String{4}, '=',':');
                delete(axes(1));
                xlabel([]);
                ylabel([]);
                title([]);
                xticks([]);
                yticks([]);
                str = {num2str(t, 't:%.2f')};
                str{end+1} = strrep(str_lam, ' ', '');
                str{end+1} = strrep(str_s, ' ', '');
                str{end+1} = strrep(str_r2, ' ','');
                text(0,0.5,str,'fontsize',15,'color','r','unit','normalized');
                if i==1
                    textbp(num2str(fits_res.shotno,'#%i'),'fontsize',18,'color','c');
                end
                vline(0, 'k');
            end
        end
    end
end