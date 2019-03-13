classdef mds < handle
    %% MDS class for connecting and reading data from a MDS server
    % Derived from handle
    %   Methods:
    %       data = mdsobj.mdsread(shotno, tree_name, tdi_exp)
    %       data_len = mdsobj.mdslen(shotno, tree_name, node_name)
    %       curr_shot = mdsobj.mdscurrentshot
    %       dims = mdsobj.mdsdims(shotno, tree_name, node_name)
    
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
            'efit_east', ...
            'efitrt_east', ...
            'nbi_east', ...
            'icrf_east', ...
            'ecrh_east', ...
            'analysis', ...
            'mpi_east', ...
            'cxrs_east'};
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
        function [data, status] = mdsread(mdsobj, shotno, tree_name, tdi_exp)
            %% read data from mds server
            % data = mdsobj.mdsread(shotno, tree_name, tdi_exp)
            
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
            if ~isnumeric(status) || isempty(status) || status~= shotno
                warning(['Cannot open #',...
                    num2str(shotno),...
                    ' under tree "',...
                    tree_name '"!']);
                status = 0;
                data = [];
                return
            end
            % read data
            disp(['mdsread: ' tdi_exp]);
            data = mdsvalue(tdi_exp);
            if ~isnumeric(data)
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
        function data_len = mdslen(mdsobj, shotno, tree_name, node_name)
        %% read signal size from mds server
        % data_len = mdsobj.mdslen(shotno, tree_name, node_name)
            node_name = mdsobj.revisenodename(node_name);
            tdi_exp = ['size(\', node_name, ')'];
            data_len = mdsobj.mdsread(shotno, tree_name, tdi_exp);
        end
        function curr_shot = mdscurrentshot(mdsobj)
        %% get current shot of total shotlist in MDS server
        % curr_shot = mdsobj.mdscurrentshot
        
            % connect to server
            mdsobj.connect
            % get current shot
            curr_shot = mdsvalue('current_shot("pcs_east")');
        end
        function dims = mdsdims(mdsobj, shotno, tree_name, node_name)
        %% read signal dimension
        % dims = mdsobj.mdsdims(shotno, tree_name, node_name)
            dims=[];
            i = 0;
            node_name = mdsobj.revisenodename(node_name);
            while(1)
                tdi_exp = ['size(\' node_name ',' num2str(i) ')'];
                status = 1;
                if status == 1
                    warning('off')
                    [dim_length, status] = mdsobj.mdsread(shotno, tree_name, tdi_exp);
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
        end
    end
end
