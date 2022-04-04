classdef mds < handle
    %% MDS class for connecting and reading data from a MDS server
    % Derived from handle
    %   Methods:
    %       data = mdsobj.mdsread(shotno, tree_name, tdi_exp)
    %       data_len = mdsobj.mdslen(shotno, tree_name, node_name)
    %       curr_shot = mdsobj.mdscurrentshot
    %       dims = mdsobj.mdsdims(shotno, tree_name, node_name)
    %       datetime = mdsdatetime(shotno)
    
    % Xiang Liu@ASIPP 2018-8-4
    % jent.le@hotmail.com
    
    properties(Constant, Access = protected)
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
            'txcs_east'};
    end
    methods(Access = protected)
    %% private methods
        function connect(mdsobj)
            if exist('mdsInfo.m', 'file')
                status = mdsInfo;
                if status.isConnected
                    return
                end
            end
%            global isMDSConnected;
%            if isMDSConnected
%                return
%            end
            mdsconnect(mdsobj.IpAddr);
%            isMDSConnected = 1;
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
        function mdsobj = mds
            %% initialize a mds server instance
            mdsobj.connect;
        end
        function [data, status] = mdsread(mdsobj, shotno, tree_name, tdi_exp, disp_option)
            %% read data from mds server
            % data = mdsobj.mdsread(shotno, tree_name, tdi_exp)
            % data = mdsobj.mdsread(shotno, tree_name, tdi_exp, disp_option)
            % Arg disp_option:
            %     0: turn off
            %     1: display all, [default]
            %     2: overwrite display
            
            if nargin < 5
                disp_option = 1;
            end
            assert(sum([0 1 2]==disp_option) > 0, 'disp_option value should be in [0, 1, 2]');
            
            % connect to server
            mdsobj.connect
            % check arguments
            if isempty(shotno) || shotno <= 0
                error('Invalid shotno inputted, it should be greater than 0!');
            end
            if ~haselement(mds.TreeNameList, tree_name)
                error(['mds has no tree named as "', tree_name, '"!']);
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
        function [data_len, status] = mdslen(mdsobj, shotno, tree_name, node_name)
        %% read signal size from mds server
        % data_len = mdsobj.mdslen(shotno, tree_name, node_name)
            node_name = mdsobj.revisenodename(node_name);
            tdi_exp = ['size(\', node_name, ')'];
            [data_len, status] = mdsobj.mdsread(shotno, tree_name, tdi_exp, 0);
        end
        function curr_shot = mdscurrentshot(mdsobj, tree_name)
        %% get current shot of total shotlist in MDS server
        % curr_shot = mdsobj.mdscurrentshot
            
            % check arguments
            if nargin == 1
                cand = [];
                for i=1:length(mdsobj.TreeNameList)
                    tree_name = mdsobj.TreeNameList{i};
                    tmp_shot = mdsobj.mdscurrentshot(tree_name);
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
            mdsobj.connect
            % get current shot
            curr_shot = mdsvalue(['current_shot("' tree_name '")']);
            % check value
            if ~isnumeric(curr_shot) || isnan(curr_shot)
                curr_shot = [];
            end
        end
        function [dims, status] = mdsdims(mdsobj, shotno, tree_name, node_name, disp_option)
        %% read signal dimension
        % dims = mdsobj.mdsdims(shotno, tree_name, node_name)
        % dims = mdsobj.mdsdims(shotno, tree_name, node_name, disp_option)
            if nargin < 5
                disp_option = 1;
            end
            dims=[];
            i = 0;
            node_name = mdsobj.revisenodename(node_name);
            while(1)
                tdi_exp = ['size(\' node_name ',' num2str(i) ')'];
                status = 1;
                if status == 1
                    warning('off')
                    [dim_length, status] = mdsobj.mdsread(shotno, tree_name, tdi_exp, disp_option);
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
        function date_time = mdsdatetime(mdsobj, shotno)
            dt_str = mdsobj.mdsread(shotno, 'east', '\ipm:createtime');
            date_time = datetime(datevec(dt_str, 'yyyy/mm/dd HH:MM:SS'));
        end
    end
end
