%% Calculated physical data class for divlp
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2019-08-30
classdef prbdatacal < prbbase & signal
    properties
        phy_type
    end
    properties(Access=protected)
        prbd_cell
        phytype_list
    end
    methods(Access=protected)
        function prbdcell_check(inst, prbd_cell)
            %% prbdataraw or prbdatacal type
            if isa(prbd_cell, 'prbdataraw') || isa(prbd_cell, 'prbdatacal')
                prbd_cell = {prbd_cell};
            end
            %% cell type
            if ~iscell(prbd_cell)
                error('prbd_cell is neither a cell, a prbdataraw or a prbdatacal type!')
            end
            phytypes = {};
            datasizes = [];
            for i=1:length(prbd_cell)
                [res, msg] = inst.prb_is_samebranch(prbd_cell{i});
                if ~res
                    error(['prbd_cell{' num2str(i) '}:' msg ' not match!'])
                end
                if isa(prbd_cell{i}, 'prbdataraw') || isa(prbd_cell{i}, 'prbdatacal')
                    phytypes{end+1} = prbd_cell{i}.phy_type;
                else
                    error(['prbd_cell{' num2str(i) '} is not a prbdataraw or prbdatacal type!'])
                end
                datasizes = [datasizes size(prbd_cell{i}.data)];
            end
            % unique?
            if length(phytypes) ~= length(unique(phytypes))
                error('prbd_cell has duplicate elements!')
            end
            % same data size?
            if length(unique(datasizes)) ~= 2
                error('elements in prbd_cell have different data size!')
            end
            inst.prbd_cell = prbd_cell;
            inst.phytype_list = phytypes;
        end
        
        function prbd = prbdcell_extract(inst, phy_type)
            [found, ind] = haselement(inst.phytype_list, phy_type);
            if ~found
                error(['prbd_cell has no "' phy_type '" data!'])
            end
            prbd = inst.prbd_cell{ind};
        end
        
        function set_attribs(inst, pd_raw)
            inst.treename = pd_raw.treename;
            inst.nodename = pd_raw.nodename;
            for i=1:length(inst.nodename)
                inst.nodename{i} = strrep(inst.nodename{i}, pd_raw.phy_type, inst.phy_type);
            end
        end
        
        function cal_js(inst)            
            A = inst.prb_extract_headarea();
            is = inst.prbdcell_extract('is');
            
            inst.phy_type = 'js';
            inst.time = is.time;
%             inst.data = abs(is.data)./1.5./A;%[Acm-2]: ion saturation current density, R_is=1.5 Ohm, Ap=2.5mm^2@2014.
            inst.data = is.data./1.5./A; % backgrounds have already been considered, this could verify if a signal is valid or not
            inst.set_attribs(is);
        end
        
        function cal_te(inst)
            vp = inst.prbdcell_extract('vp');
            vf = inst.prbdcell_extract('vf');
            te_val = (51*vp.data - 21*vf.data)./log(2);%[eV]: electron temperature.
%             te_val = te_val.*(te_val>=0.1) + 1*(te_val<0.1); % 1* can not be omitted, otherwise, data type will be logical
%             te_val(te_val<0.1) = nan;
            
            inst.phy_type = 'te';
            inst.time = vp.time;
            inst.data = te_val;
            inst.set_attribs(vp);
        end
        
        function cal_ne(inst)
            A  = inst.prb_extract_headarea();
            is = inst.prbdcell_extract('is');
            te = inst.prbdcell_extract('te'); te.data=abs(te.data);
            ne_val = (abs(is.data)*73.3./sqrt(te.data))/sqrt(2)*8.22/A*1e-1;%[10^19m-3]:electron density, According to Guo and JET probe thesis
            
            inst.phy_type = 'ne';
            inst.time = is.time;
            inst.data = ne_val;
            inst.set_attribs(is);
        end
        
        function cal_pe(inst)
            te = inst.prbdcell_extract('te');
            ne = inst.prbdcell_extract('ne');
            
            inst.phy_type = 'pe';
            inst.time = te.time;
%             inst.data = te.data.*ne.data*1.6e-19*1e19;
            inst.data = te.data.*ne.data*1.6;
            inst.set_attribs(ne);
        end
        
        function cal_qpar(inst)
            gamma = 7; % gamma_i+gamma_e
            te = inst.prbdcell_extract('te');
            js = inst.prbdcell_extract('js');
            
            inst.phy_type = 'qpar';
            inst.time = te.time;
            inst.data = gamma*js.data*1e4.*te.data*1e-6; %[MWm-2];qpar = gamma*Gamma*Te = gamma*js/e*te*e = gamma*js*te
            inst.set_attribs(js);
        end
    end
    methods
        function inst = prbdatacal(varargin)
            inst = inst@prbbase(varargin{:});
        end
        
        function prb_calculate(inst, derive_type, prbd_cell)
            %% check arguments
            derive_type = inst.check_dertype(derive_type);
            inst.prbdcell_check(prbd_cell);
            %% calculate derived phyical data
            switch derive_type
                case 'js'
                    inst.cal_js();
                case 'te'
                    inst.cal_te();
                case 'ne'
                    inst.cal_ne();
                case 'pe'
                    inst.cal_pe();
                case 'qpar'
                    inst.cal_qpar();
                otherwise
                    error('Unknown derive_type!')
            end
        end
    end
end