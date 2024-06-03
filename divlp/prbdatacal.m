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
        function prbdcell_check(self, prbd_cell)
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
                [res, msg] = self.prb_is_samebranch(prbd_cell{i});
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
            self.prbd_cell = prbd_cell;
            self.phytype_list = phytypes;
        end
        
        function prbd = prbdcell_extract(self, phy_type)
            [found, ind] = haselement(self.phytype_list, phy_type);
            if ~found
                error(['prbd_cell has no "' phy_type '" data!'])
            end
            prbd = self.prbd_cell{ind};
        end
        
        function set_attribs(self, pd_raw)
            self.treename = pd_raw.treename;
            self.nodename = pd_raw.nodename;
            for i=1:length(self.nodename)
                self.nodename{i} = strrep(self.nodename{i}, pd_raw.phy_type, self.phy_type);
            end
        end
        
        function cal_js(self)            
            A = self.prb_extract_headarea();
            is = self.prbdcell_extract('is');
            
            self.phy_type = 'js';
            self.time = is.time;
%             self.data = abs(is.data)./1.5./A;%[Acm-2]: ion saturation current density, R_is=1.5 Ohm, Ap=2.5mm^2@2014.
            self.data = is.data./1.5./A; % backgrounds have already been considered, this could verify if a signal is valid or not
            self.set_attribs(is);
        end
        
        function cal_te(self)
            vp = self.prbdcell_extract('vp');
            vf = self.prbdcell_extract('vf');
            te_val = (51*vp.data - 21*vf.data)./log(2);%[eV]: electron temperature.
%             te_val = te_val.*(te_val>=0.1) + 1*(te_val<0.1); % 1* can not be omitted, otherwise, data type will be logical
%             te_val(te_val<0.1) = nan;
            
            self.phy_type = 'te';
            self.time = vp.time;
            self.data = te_val;
            self.set_attribs(vp);
        end
        
        function cal_ne(self)
            A  = self.prb_extract_headarea();
            is = self.prbdcell_extract('is');
            te = self.prbdcell_extract('te'); te.data=abs(te.data);
            ne_val = (abs(is.data)*73.3./sqrt(te.data))/sqrt(2)*8.22/A*1e-1;%[10^19m-3]:electron density, According to Guo and JET probe thesis
            
            self.phy_type = 'ne';
            self.time = is.time;
            self.data = ne_val;
            self.set_attribs(is);
        end
        
        function cal_pe(self)
            te = self.prbdcell_extract('te');
            ne = self.prbdcell_extract('ne');
            
            self.phy_type = 'pe';
            self.time = te.time;
%             self.data = te.data.*ne.data*1.6e-19*1e19;
            self.data = te.data.*ne.data*1.6;
            self.set_attribs(ne);
        end
        
        function cal_qpar(self)
            gamma = 7; % gamma_i+gamma_e
            te = self.prbdcell_extract('te');
            js = self.prbdcell_extract('js');
            
            self.phy_type = 'qpar';
            self.time = te.time;
            self.data = gamma*js.data*1e4.*te.data*1e-6; %[MWm-2];qpar = gamma*Gamma*Te = gamma*js/e*te*e = gamma*js*te
            self.set_attribs(js);
        end
    end
    
    methods
        function self = prbdatacal(varargin)
            self = self@prbbase(varargin{:});
        end
        
        function prb_calculate(self, derive_type, prbd_cell)
            %% check arguments
            derive_type = self.check_dertype(derive_type);
            self.prbdcell_check(prbd_cell);
            %% calculate derived phyical data
            switch derive_type
                case 'js'
                    self.cal_js();
                case 'te'
                    self.cal_te();
                case 'ne'
                    self.cal_ne();
                case 'pe'
                    self.cal_pe();
                case 'qpar'
                    self.cal_qpar();
                otherwise
                    error('Unknown derive_type!')
            end
        end
    end
end