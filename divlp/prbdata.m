%% Data loader class for divlp
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2019-08-30
classdef prbdata < prbbase
    properties(Access=protected)
        tree_switched = 0;
    end
    
    properties
        is;
        vp;
        vf;
        js;
        te;
        ne;
        pe;
        qpar;
    end
    
    methods(Access=protected)
        function res = is_loaded(self, phy_type)
            phy_type = self.check_phytype(phy_type);
            res = 1;
            tmp_prbd = self.(phy_type);
            if ( isa(tmp_prbd, 'prbdataraw') || isa(tmp_prbd, 'prbdatacal') ) && ...
                    isequal(tmp_prbd.phy_type, phy_type) && ...
                    tmp_prbd.shotno == self.check_shotno() && ...
                    isequal(tmp_prbd.position_tag, self.check_postag()) && ...
                    isequal(tmp_prbd.port_name, self.check_portname()) && ...
                    ~isempty(tmp_prbd.data) && ~isempty(tmp_prbd.time)                 
                return
            end
            res = 0;
        end
    end
    
    methods
        function self = prbdata(varargin)
            self = self@prbbase(varargin{:});
        end
        
        function load(self, phy_type, time_range)
            %% check arguments
            if nargin == 2
                time_range = [];
            end
            %% check if data loaded
            phy_type = self.check_phytype(phy_type);
            if self.is_loaded(phy_type)
                return
            end
            %% load raw data
            if haselement(prbbase.prb_get_const('prbtype'), phy_type)
                self.(phy_type) = prbdataraw(self.check_shotno(), self.check_postag(), self.check_portname());
                if self.tree_switched
                    self.(phy_type).prb_switch_tree();
                end
                self.(phy_type).prb_read(phy_type, time_range);
                return
            end
            %% cal data
            prbdc = prbdatacal(self.check_shotno(), self.check_postag(), self.check_portname());
            switch phy_type
                case 'js'
                    self.load('is', time_range);
                    prbdata_cell = self.is;
                case 'te'
                    self.load('vp', time_range);
                    self.load('vf', time_range);
                    prbdata_cell = {self.vp, self.vf};
                case 'ne'
                    self.load('is', time_range);
                    self.load('te', time_range);
                    prbdata_cell = {self.is, self.te};
                case 'pe'
                    self.load('ne', time_range);
                    self.load('te', time_range);
                    prbdata_cell = {self.ne, self.te};
                case 'qpar'
                    self.load('js', time_range);
                    self.load('te', time_range);
                    prbdata_cell = {self.js, self.te};
                otherwise
                    error('Unknown phy_type!')
            end
            prbdc.prb_calculate(phy_type, prbdata_cell);
            self.(phy_type) = prbdc;
        end
        
        function fig = plot3d(self, phy_type, varargin)
            if ~self.is_loaded(phy_type)
                error(['load "' phy_type '" first!'])
            end
            Args.YAxisType = 'dist2div';
            Args.DownSampling = 10;
            Args.OmitNan = 0;
            Args.InterpNan = 0;
            Args.ShowXLabel = 1;
            Args.ShowYLabel = 1;
            Args.ShowColorBar = 1;
            Args.FontSize = 20;
            Args.TimeRange = [];
            Args = parseArgs(varargin, Args, {'OmitNan', 'InterpNan', 'ShowXLabel', 'ShowYLabel'});
            yaxis_type = argstrchk({'channel', 'dist2div'}, Args.YAxisType);
            prbd = self.(phy_type);
            x = prbd.time;
            y = self.prb_extract_distinfo(yaxis_type);
            z = prbd.data;
            ind = findvalue(x, 0);
            x = x(ind:end);
            z = z(:,ind:end);
            if strcmpi(Args.YAxisType, 'dist2div')
                y = y/10;
            end
            if Args.DownSampling > 1
                x = downsamplebymean(x, Args.DownSampling);
                z = downsamplebymean(z, Args.DownSampling);
            end
            if Args.OmitNan
                inds_bad = false(1, length(y));
                for i=1:length(y)
                    if sum(isnan(z(i,:)))
                        inds_bad(i) = true;
                    end
                end
                if Args.InterpNan
                    for i=1:length(x)
                        z(inds_bad, i) = interp1(y(~inds_bad), z(~inds_bad, i), y(inds_bad), 'PCHIP');
                    end
                else
                    y(inds_bad) = [];
                    z(inds_bad,:) = [];
                end
            end
            if ~isempty(Args.TimeRange)
                time_range = mergeintervals(x([1 end]), Args.TimeRange);
                time_rng_inds = findvalue(x, time_range);
                x = x(time_rng_inds(1):time_rng_inds(2));
                z = z(:, time_rng_inds(1):time_rng_inds(2));
            end
            fig = figure(gcf);
            contourfjet(x, y, z);
            if Args.ShowXLabel
                xlabel('Time [s]')
            end
            if Args.ShowYLabel
                y_label = yaxis_type;
                if strcmpi(Args.YAxisType, 'dist2div')
                    y_label = 'Dist2Corner [cm]';
                end
                ylabel(y_label)
            end
            if Args.ShowColorBar
                colorbar;
            end
            set(gca, 'fontsize', Args.FontSize);
        end
        
        function fig = plot2d(self, phy_type, times, varargin)
            if ~self.is_loaded(phy_type)
                error(['load "' phy_type '" first!'])
            end
            Args.YAxisType = 'dist2div';
            Args.AvgTime = 0.05;
            Args.MarkerSize = 8;
            Args.LineWidth = 2;
            Args.FontSize = 20;
            Args = parseArgs(varargin, Args);
            yaxis_type = argstrchk({'channel', 'dist2div'}, Args.YAxisType);
            prbd = self.(phy_type);
            x = prbd.time;
            y = self.prb_extract_distinfo(yaxis_type);
            z = prbd.data;
            dt = mean(diff(x));
            len = ceil(Args.AvgTime/dt/2);
            fig = figure(gcf);
            legend_str = {};
            for i=1:length(times)
                t = times(i);
                if t > x(end)-Args.AvgTime || t < x(1)+Args.AvgTime
                    warning('time is out of range, be skipped!')
                    continue
                end
                ind = findvalue(x, t);
                z_val = mean(z(:,(ind-len):(ind+len)),2,'omitnan');
                z_err = std(z(:,(ind-len):(ind+len)),0,2,'omitnan');
                errorbar(y, z_val, z_err, 's', 'markersize',Args.MarkerSize, 'linewidth', Args.LineWidth);
                hold on
                legend_str{end+1} = num2str(t,'t=%.2fs');
            end
            set(gca, 'fontsize', Args.FontSize);
            xlabel(yaxis_type)
            ylabel(prbd.prb_get_phytype(phy_type))
            legend(legend_str)
        end
        
        function switch_tree(self)
            self.tree_switched = ~self.tree_switched;
        end
    end
end