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
        function res = is_loaded(inst, phy_type)
            phy_type = inst.check_phytype(phy_type);
            res = 1;
            tmp_prbd = inst.(phy_type);
            if ( isa(tmp_prbd, 'prbdataraw') || isa(tmp_prbd, 'prbdatacal') ) && ...
                    isequal(tmp_prbd.phy_type, phy_type) && ...
                    tmp_prbd.shotno == inst.check_shotno() && ...
                    isequal(tmp_prbd.position_tag, inst.check_postag()) && ...
                    isequal(tmp_prbd.port_name, inst.check_portname()) && ...
                    ~isempty(tmp_prbd.data) && ~isempty(tmp_prbd.time)                 
                return
            end
            res = 0;
        end
    end
    methods
        function inst = prbdata(varargin)
            inst = inst@prbbase(varargin{:});
        end
        
        function load(inst, phy_type, time_range)
            %% check arguments
            if nargin == 2
                time_range = [];
            end
            %% check if data loaded
            phy_type = inst.check_phytype(phy_type);
            if inst.is_loaded(phy_type)
                return
            end
            %% load raw data
            if haselement(prbbase.prb_get_const('prbtype'), phy_type)
                inst.(phy_type) = prbdataraw(inst.check_shotno(), inst.check_postag(), inst.check_portname());
                if inst.tree_switched
                    inst.(phy_type).prb_switch_tree();
                end
                inst.(phy_type).prb_read(phy_type, time_range);
                return
            end
            %% cal data
            prbdc = prbdatacal(inst.check_shotno(), inst.check_postag(), inst.check_portname());
            switch phy_type
                case 'js'
                    inst.load('is', time_range);
                    prbdata_cell = inst.is;
                case 'te'
                    inst.load('vp', time_range);
                    inst.load('vf', time_range);
                    prbdata_cell = {inst.vp, inst.vf};
                case 'ne'
                    inst.load('is', time_range);
                    inst.load('te', time_range);
                    prbdata_cell = {inst.is, inst.te};
                case 'pe'
                    inst.load('ne', time_range);
                    inst.load('te', time_range);
                    prbdata_cell = {inst.ne, inst.te};
                case 'qpar'
                    inst.load('js', time_range);
                    inst.load('te', time_range);
                    prbdata_cell = {inst.js, inst.te};
                otherwise
                    error('Unknown phy_type!')
            end
            prbdc.prb_calculate(phy_type, prbdata_cell);
            inst.(phy_type) = prbdc;
        end
        
        function fig = plot3d(inst, phy_type, varargin)
            if ~inst.is_loaded(phy_type)
                error(['load "' phy_type '" first!'])
            end
            Args.YAxisType = 'dist2div';
            Args.DownSampling = 10;
            Args.OmitNan = 0;
            Args.ShowXLabel = 1;
            Args.ShowYLabel = 1;
            Args.ShowColorBar = 1;
            Args.FontSize = 20;
            Args = parseArgs(varargin, Args, {'OmitNan', 'ShowXLabel', 'ShowYLabel'});
            yaxis_type = argstrchk({'channel', 'dist2div'}, Args.YAxisType);
            prbd = inst.(phy_type);
            x = prbd.time;
            y = inst.prb_extract_distinfo(yaxis_type);
            z = prbd.data;
            ind = findvalue(x, 0);
            x = x(ind:end);
            z = z(:,ind:end);
            if Args.DownSampling > 1
                x = downsamplebymean(x, Args.DownSampling);
                z = downsamplebymean(z, Args.DownSampling);
            end
            if Args.OmitNan
                inds_bad = [];
                for i=1:size(z, 1)
                    if sum(isnan(z(i,:)))
                        inds_bad = i;
                    end
                end
                y(inds_bad) = [];
                z(inds_bad,:) = [];
            end
            fig = figure(gcf);
            contourfjet(x, y, z);
            if Args.ShowXLabel
                xlabel('Time [s]')
            end
            if Args.ShowYLabel
                ylabel(yaxis_type)
            end
            if Args.ShowColorBar
                colorbar;
            end
            set(gca, 'fontsize', Args.FontSize);
        end
        
        function fig = plot2d(inst, phy_type, times, varargin)
            if ~inst.is_loaded(phy_type)
                error(['load "' phy_type '" first!'])
            end
            Args.YAxisType = 'dist2div';
            Args.AvgTime = 0.05;
            Args.MarkerSize = 8;
            Args.LineWidth = 2;
            Args.FontSize = 20;
            Args = parseArgs(varargin, Args);
            yaxis_type = argstrchk({'channel', 'dist2div'}, Args.YAxisType);
            prbd = inst.(phy_type);
            x = prbd.time;
            y = inst.prb_extract_distinfo(yaxis_type);
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
        
        function switch_tree(inst)
            inst.tree_switched = ~inst.tree_switched;
        end
    end
end