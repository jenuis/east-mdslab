%% Base Class for divlp
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2019-08-30
classdef prbbase < mdsbase    
    properties(Access=protected, Constant)
        POS_TAG  = {'UI', 'UO', 'LI', 'LO'};
        PRB_TYPE = {'i_s', 'v_p', 'v_f'};
        DER_TYPE = {'j_s', 'T_e', 'n_e', 'p_e', 'q_{par}'};
        PHY_TYPE = [prbbase.PRB_TYPE, prbbase.DER_TYPE{:}];
    end
    
    properties(Access=protected)
        position_tag
        port_name
        distrib_info
        head_area
        daq_info
    end
    
    methods(Access=protected, Static)        
        function probe_type = check_prbtype(probe_type)
            probe_type = argstrchk(prbbase.PRB_TYPE, probe_type);
        end
        
        function derive_type = check_dertype(derive_type)
            derive_type = argstrchk(prbbase.DER_TYPE, derive_type);
        end
        
        function phy_type = check_phytype(phy_type)
            phy_type = argstrchk(prbbase.PHY_TYPE, phy_type);
        end
        
    end
    
    methods(Static)
        function res = prb_get_const(const_type, use_original)
            if nargin == 1
                use_original = 0;
            end
            if ~ischar(const_type)
                error('argument const_type is not a string!')
            end
            const_type = lower(strrmsymbol(const_type));
            switch const_type
                case 'postag'
                    res = prbbase.POS_TAG;
                case 'prbtype'
                    res = prbbase.PRB_TYPE;
                case 'dertype'
                    res = prbbase.DER_TYPE;
                case 'phytype'
                    res = prbbase.PHY_TYPE;
                otherwise
                    error('unknown constant type!')
            end
            if use_original
                return
            end
            for i=1:length(res)
                res{i} = lower(strrmsymbol(res{i}));
            end
        end
        
        function res = prb_get_phytype(phy_type)
            res = [];
            [found, ind] = haselement(prbbase.prb_get_const('phytype'), phy_type);
            if found
                res = prbbase.PHY_TYPE{ind};
            end
        end
    end
    
    methods(Access=protected)
        function shotno = check_shotno(self, shotno)
            if nargin == 2
                self.shotno = shotno;
            end
            self.shotnocheck();
            shotno = self.shotno;
        end
        
        function position_tag = check_postag(self, position_tag)
            if nargin == 2
                self.position_tag = position_tag;
            end
            if isempty(self.position_tag)
                error('please call "prb_set_postag" to set attribute "position_tag"!')
            end
            self.position_tag = argstrchk(prbbase.POS_TAG, self.position_tag);
            position_tag = self.position_tag;
        end
        
        function port_name = check_portname(self, port_name)
            if nargin == 2
                self.port_name = port_name;
            end
            if isnumeric(self.port_name) && isempty(self.port_name)
                error('please call "prb_set_portname" to set attribute "port_name"!')
            end
            self.port_name = argstrchk(self.prb_list_portnames(), self.port_name);
            port_name = self.port_name;
        end
        
        function distrib_info = check_distinfo(self)
            if isempty(self.distrib_info)
                error('please call "prb_load_sys" to set attribute "distrb_info"!')
            end
            distrib_info = self.distrib_info;
        end
        
        function head_area = check_headarea(self)
            if isempty(self.head_area)
                error('please call "prb_load_sys" to set attribute "head_area"!')
            end
            head_area = self.head_area;
        end
        
        function val = read_config(~, key, ini_file)
            if nargin < 3
                ini_file = fullfile(getuserdir, 'divlp.ini');
            end
            if ~exist(ini_file, 'file')
                error(['Can not find "divlp.ini" under "' getuserdir '"!']);
            end
            conf = ini2struct(ini_file);
            if ~fieldexist(conf, key)
                error(['"' key '" is not specified in "divlp.ini"!'])
            end
            val = conf.(key);
        end
    end
    
    methods
        function self = prbbase(shotno, position_tag, port_name)
            if nargin >= 1
                self.check_shotno(shotno);
                self.prb_load_sys();
            end
            if nargin >= 2
                self.check_postag(position_tag);
            end
            if nargin >= 3
                self.check_portname(port_name);
            end
        end
        
        function prb_set_postag(self, pos_tag)
            self.check_postag(pos_tag);
        end
        
        function prb_set_portname(self, port_name)
            self.check_portname(port_name);
        end
        
        function postag = prb_get_postag(self)
            postag = self.check_postag();
        end
        
        function portname = prb_get_portname(self)
            portname = self.check_portname();
        end
        
        function prb_load_sys(self)
            shotno = self.check_shotno();
            sys_path = fullfile(self.read_config('user_path'), 'sys');
            addpath(sys_path);
            if isempty(self.distrib_info)
                self.distrib_info = divprb_distrib_info(shotno);
            end
            if isempty(self.head_area)
                self.head_area = divprb_head_area(shotno);
            end
            if isempty(self.daq_info)
                self.daq_info = divprb_daq_info(shotno);
            end
            rmpath(sys_path);
        end
               
        function res = prb_extract_distinfo(self, data_type)
            %% extract distrib_info by position_tag
            dist_info = self.check_distinfo();
            res_pos = dist_info.(self.check_postag());
            %% locate portname
            [~, port_ind] = haselement(res_pos(:,1), self.check_portname());
            res_port = res_pos(port_ind,:);
            %% locate data_type
            switch data_type
                case 'channel'
                    res = res_port{2};
                case 'dist2div'
                    res = res_port{3}(1,:);
                case 'r'
                    res = res_port{3}(2,:);
                case 'z'
                    res = res_port{3}(3,:);
                case 'rz'
                    res = res_port{3}(2:3,:);
                otherwise
                    error('invalid data_type to extract distrb_info!')
            end
        end
        
        function res = prb_extract_daqinfo(self, info_type, prb_type)
            switch lower(info_type)
                case 'sign'
                    field_names = {...
                        self.check_postag(),...
                        self.check_portname(),...
                        self.check_prbtype(prb_type)};

                    res = self.daq_info.sign;
                    for i=1:length(field_names)
                        fname = field_names{i};
                        if ~fieldexist(res, fname)
                            res = 1;
                            break;
                        end
                        res = res.(fname);
                    end
                otherwise
                    error('Unrecognized info_type!')
            end
        end
        
        function res = prb_list_portnames(self)
            dist_info = self.check_distinfo();
            res_pos = dist_info.(self.check_postag());
            res = res_pos(:,1);
        end
        
        function res = prb_extract_headarea(self)
            A = self.check_headarea();
            res = A.(self.check_postag());
        end
                
        function [res, msg] = prb_is_samebranch(self, test)
            if isa(test, 'prbbase')
                shotno = test.shotno;
                positiontag = test.prb_get_postag();
                portname = test.prb_get_portname();
            elseif fieldexist(test, 'shotno') && fieldexist(test, 'position_tag') && fieldexist(test, 'port_name')
                shotno = test.shotno;
                positiontag = test.position_tag;
                portname = test.port_name;
            else
                error('not a prbbase type or do not have full branch information!')
            end
            res = 1;
            msg = [];
            if ~isequal(self.check_shotno(), shotno)
                res = 0; msg = 'shotno'; return
            end
            if ~isequal(self.check_postag(), positiontag)
                res = 0; msg = 'postition_tag'; return
            end
            if ~isequal(self.check_portname(), portname)
                res = 0; msg = 'port_name'; return
            end
        end
    end
end