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
            'east',...
            'east_1',...
            'pcs_east',...
            'eng_tree',...
            'efit_east',...
            'efitrt_east',...
            'nbi_east',...
            'icrf_east',...
            'ecrh_east',...
            'analysis',...
            'mpi_east'};
    end
    methods(Access = protected)
    %% private methods
        function connect(mdsobj)
            mdsconnect(mdsobj.IpAddr);
        end
        function new_nodename = revisenodename(~, node_name)
            if ~isempty(node_name) && ischar(node_name) && node_name(1) == '\'
                new_nodename = node_name(2:end);
                return
            end
            new_nodename = node_name;
        end
        function confirm_connection(mdsobj)
            status = mdsInfo;
            if status.isConnected
                return
            end
            mdsdisconnect
            mdsobj.connect
            status = mdsInfo;
            if status.isConnected
                return
            end
            error('can not reach to server!');
        end
    end
    methods
    %% public methods
        function mdsobj = mds
            %% initialize a mds server instance
            mdsobj.connect;
            mdsobj.confirm_connection;
        end
        function data = mdsread(mdsobj, shotno, tree_name, tdi_exp)
            %% read data from mds server
            % data = mdsobj.mdsread(shotno, tree_name, tdi_exp)
            
            % confirm connection to server
            mdsobj.confirm_connection
            % check arguments
            if isempty(shotno) || shotno <= 0 || shotno > mdsobj.mdscurrentshot
                error('Invalid shotno inputted, it should be greater than 0 and less than current shot!');
            end
            if ~haselement(mds.TreeNameList, tree_name)
                error(['mds has no tree named as "', tree_name, '"!']);
            end
            % open tree
            status = mdsopen(tree_name, shotno);
            if ~isnumeric(status) || isempty(status) || status~= shotno
                error(['Cannot open #',...
                    num2str(shotno),...
                    ' under tree "',...
                    tree_name '"!']);
            end
            % read data
            disp(['mdsread: ' tdi_exp]);
            data = mdsvalue(tdi_exp);
            if ~isnumeric(data)
                error(['Retrieve value failed for #',...
                    num2str(shotno), ' under tree "',...
                    tree_name, '" with TDI expression: "',...
                    tdi_exp, '"!']);
            end
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
        
            % confirm connection to server
            mdsobj.confirm_connection
            % get current shot
            curr_shot = mdsvalue('current_shot("east")');
        end
        function dims = mdsdims(mdsobj, shotno, tree_name, node_name)
        %% read signal dimension
        % dims = mdsobj.mdsdims(shotno, tree_name, node_name)
            dims=[];
            i = 0;
            node_name = mdsobj.revisenodename(node_name);
            while(1)
                tdi_exp = ['size(\' node_name ',' num2str(i) ')'];
                try
                    dim_length = mdsobj.mdsread(shotno, tree_name, tdi_exp);
                    if isnumeric(dim_length) && ~isempty(dim_length)
                        dims(end+1) = dim_length;
                        i = i+1;
                    else
                        break
                    end
                catch
                    break
                end
            end
        end
    end
end
