%% API class to communicate with MDSPlus server for mdslib
% -------------------------------------------------------------------------
% Copyright 2019-2024 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2018-8-4
%   Methods:
%       data = self.mdsread(shotno, tree_name, tdi_exp)
%       data_len = self.mdslen(shotno, tree_name, node_name)
%       curr_shot = self.mdscurrentshot
%       dims = self.mdsdims(shotno, tree_name, node_name)
%       datetime = mdsdatetime(shotno)
classdef mds < handle   
    properties(Access = protected)
    %% constant properties
        IpAddr = 'mds.ipp.ac.cn';
        TreeNameList = {...
            'east', ...
            'east_1', ...
            'pcs_east', ...
            'eng_tree', ...
            'p_efit', ...
            'efit_east', ...
            'efitrt_east', ...
            'nbi_east', ...
            'icrf_east', ...
            'ecrh_east', ...
            'analysis', ...
            'mpi_east', ...
            'cxrs_east', ...
            'txcs_east', ...
            'energy_east'};
    end
    
    methods(Access = protected)
    %% private methods
        function get_env_set_props(self)
            % set MDS server IP address
            ip_addr = getenv('MDS_SERVER');
            if isempty(ip_addr)
                warning(['Enviroment variable "MDS_SERVER" not set. Using default ("' self.IpAddr '").'])
                setenv('MDS_SERVER', self.IpAddr);
            else
                self.IpAddr = ip_addr;
            end
            % set valid tree name list
            tree_name_str = getenv('MDS_TREE_NAMES');
            if isempty(tree_name_str)
                tree_name_str = strjoin(self.TreeNameList, ','); 
                warning(['Enviroment variable "MDS_TREE_NAMES" not set. Using default ("' tree_name_str '").']);
                setenv('MDS_TREE_NAMES', tree_name_str);
            else
                self.TreeNameList = strsplit(tree_name_str, ',');
            end
        end
    
        function connect(self)
            if exist('mdsInfo.m', 'file')
                status = mdsInfo;
                if status.isConnected
                    return
                end
            end
            mdsconnect(self.IpAddr);
        end
        
        function new_nodename = revisenodename(~, node_name)
            if ~isempty(node_name) && ischar(node_name) && node_name(1) == '\'
                new_nodename = node_name(2:end);
                return
            end
            new_nodename = node_name;
        end
    end
    
    methods
    %% public methods
        function self = mds
            %% initialize a mds server instance
            self.get_env_set_props();
            self.connect();
        end
        
        function [data, status] = mdsread(self, shotno, tree_name, tdi_exp, disp_option)
            %% read data from mds server
            % data = self.mdsread(shotno, tree_name, tdi_exp)
            % data = self.mdsread(shotno, tree_name, tdi_exp, disp_option)
            % Arg disp_option:
            %     0: turn off
            %     1: display all, [default]
            %     2: overwrite display
            
            if nargin < 5
                disp_option = 1;
            end
            assert(sum([0 1 2]==disp_option) > 0, 'disp_option value should be in [0, 1, 2]');
            
            % connect to server
            self.connect
            % check arguments
            if isempty(shotno) || shotno <= 0
                error('Invalid shotno inputted, it should be greater than 0!');
            end
            if ~haselement(self.TreeNameList, tree_name)
                warning(['Class "mds" does not define tree named as "', tree_name, '"!']);
            end
            % open tree
            status = mdsopen(tree_name, shotno);
            if isa(status, 'MDSplus.Int32')
                status = double(status);
            end
            if ~isnumeric(status) || (~isempty(status) && status~= shotno)
                warning(['Cannot open #',...
                    num2str(shotno),...
                    ' under tree "',...
                    tree_name '"!']);
                status = 0;
                data = [];
                return
            end
            % read data
            switch disp_option
                case 1
                    disp(['mdsread: ' tdi_exp]);
                case 2
                    tdi_exp_disp = strrep(tdi_exp, '\', ''); % dispstat use fprintf, remove '\' to avoid escape charater
                    dispstat(['mdsread: ' tdi_exp_disp]);
            end
            [data, status] = mdsvalue(tdi_exp);
            if mod(status, 2) == 0
                warning(['Retrieve value failed for #',...
                    num2str(shotno), ' under tree "',...
                    tree_name, '" with TDI expression: "',...
                    tdi_exp, '"!']);
                status = 0;
                data = [];
                return
            end
            status = 1;
        end
        
        function [data_len, status] = mdslen(self, shotno, tree_name, node_name)
        %% read signal size from mds server
        % data_len = self.mdslen(shotno, tree_name, node_name)
            node_name = self.revisenodename(node_name);
            tdi_exp = ['size(\', node_name, ')'];
            [data_len, status] = self.mdsread(shotno, tree_name, tdi_exp, 0);
        end
        
        function curr_shot = mdscurrentshot(self, tree_name)
        %% get current shot of total shotlist in MDS server
        % curr_shot = self.mdscurrentshot
            
            % check arguments
            if nargin == 1
                cand = [];
                for i=1:length(self.TreeNameList)
                    tree_name = self.TreeNameList{i};
                    tmp_shot = self.mdscurrentshot(tree_name);
                    if ~isempty(tmp_shot)
                        cand(end+1) = tmp_shot;
                    end
                end
                cand_unique = unique(cand);
                counts = countmember(cand_unique, cand);
                [~, max_ind] = max(counts);
                curr_shot = cand_unique(max_ind);
                return
            end
            % connect to server
            self.connect
            % get current shot
            curr_shot = mdsvalue(['current_shot("' tree_name '")']);
            % check value
            if ~isnumeric(curr_shot) || isnan(curr_shot)
                curr_shot = [];
            end
        end
        
        function [dims, status] = mdsdims(self, shotno, tree_name, node_name, disp_option)
        %% read signal dimension
        % dims = self.mdsdims(shotno, tree_name, node_name)
        % dims = self.mdsdims(shotno, tree_name, node_name, disp_option)
            if nargin < 5
                disp_option = 1;
            end
            node_name = self.revisenodename(node_name);
            %% new implementation
            tdi_exp = ['shape(\' node_name ')'];
            [dims, status] = self.mdsread(shotno, tree_name, tdi_exp, disp_option);
            return
            %% old implementation
            dims=[];
            i = 0;
            while(1)
                tdi_exp = ['size(\' node_name ',' num2str(i) ')'];
                status = 1;
                if status == 1
                    warning('off')
                    [dim_length, status] = self.mdsread(shotno, tree_name, tdi_exp, disp_option);
                    warning('on')
                    if isnumeric(dim_length) && ~isempty(dim_length)
                        dims(end+1) = dim_length;
                        i = i+1;
                    else
                        break
                    end
                else
                    break
                end
            end
            if ~(i == 0 && status == 0)
                status = 1;
            end
        end
        
        function date_time = mdsdatetime(self, shotno)
            dt_str = self.mdsread(shotno, 'east', '\ipm:createtime');
            date_time = datetime(datevec(dt_str, 'yyyy/mm/dd HH:MM:SS'));
        end
    end
end
