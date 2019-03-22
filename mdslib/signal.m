classdef signal < mds & basehandle
    %SIGNAL class which bundles time and data properties of a mds signal
    %Derived from mds and basehandle
    %   Instance:
    %       sigobj = signal
    %       sigobj = signal(shotno)
    %       sigobj = signal(shotno, tree_name)
    %       sigobj = signal(shotno, tree_name, node_name)
    %       sigobj = signal(shotno, tree_name, node_name, 'ReadNow', 0,...
    %                       'TimeRange', [])
    %   Props:
    %       shotno
    %       treename
    %       nodename: can be a string and a cell string of same time dimension
    %                 under same tree.
    %       time
    %       data
    %   Methods (inherited from mds):
    %       data = sigobj.mdsread(tdi_exp)
    %       data_len = sigobj.mdslen
    %       dims = sigobj.mdsdims
    %       curr_shot = mdsobj.mdscurrentshot
    %   Methods:
    %       sigobj.sigreadtime(time_range)
    %       sigobj.sigreaddata(index_range)
    %       sigobj.sigread(time_range)
    %       sigobj.sigreadbunch(node_format_str, channel_list, time_range)
    %       sliced_sigobj = sigobj.sigslice(time_range)
    %       part_data = sigobj.sigpartdata(time_range)
    %       unbund_data = sigobj.sigunbund(node_name)
    %       sigobj.sigplot
    
    % Xiang Liu@ASIPP 2017-9-12
    % jent.le@hotmail.com
    
    %% signal private properties
    properties(Access = protected)
        timesliceindex
        mdscache
    end
    %% signal public properties
    properties
        treename
        nodename
        time
        data
    end
    %% overide parent methods
    methods
        function [data, status] = mdsread(sigobj, tdi_exp)
            %% inherited from mds class
            % data = sigobj.mdsread(tdi_exp)
            [data, status] = mdsread@mds(sigobj, sigobj.shotno, sigobj.treename, tdi_exp);
        end
        function [data_len, status] = mdslen(sigobj)
            %% inherited from mds class
            % data_len = sigobj.mdslen
            mdsobj = mds; % must call mdsread within mds instance
            [data_len, status] = mdslen@mds(mdsobj, sigobj.shotno, sigobj.treename, sigobj.nodename);
        end
        function [dims, status] = mdsdims(sigobj)
            %% inherited from mds class
            % dims = sigobj.mdsdims
            mdsobj = mds; % must call mdsread within mds instance
            [dims, status] = mdsdims@mds(mdsobj, sigobj.shotno, sigobj.treename, sigobj.nodename);
        end
    end
    %% static variable
    methods (Access = protected, Static)
        function val_out = cache_option(val_in)
            persistent use_cache;
            if nargin
                use_cache = val_in;
            end
            val_out = use_cache;
        end
    end
    %% signal private methods
    methods(Access = protected)
        %% overide mds private methods
        function revisenodename(sigobj, single_node)
        %% inherited from mds class
            if nargin == 1
                single_node = 0;
            end
            sigobj.nodename = revisenodename@mds(sigobj, sigobj.nodename);
            if iscellstr(sigobj.nodename) && length(sigobj.nodename) == 1
                sigobj.nodename = sigobj.nodename{1};
            end
            if single_node && ~ischar(sigobj.nodename)
                error('One nodename check is on with more than one node!');
            end
        end
        %% private methods
        function sigdatacheck(sigobj)
            % check if data is empty
            if isempty(sigobj.data) || ~isnumeric(sigobj.data)
                error('signal data is empty!')
            end
            % check if data has same time dimension with time
            shape = size(sigobj.data);
            if shape(end) ~= length(sigobj.time)
                error('data has different length with time dimension!')
            end
        end
        function cache_sig = load_cache(sigobj, time_range, sig_time)
            if nargin == 2
                sig_time = [];
            elseif nargin == 1
                time_range = [];
                sig_time = [];
            end
            cache_sig = sigobj.mdscache.cache_read(sigobj.treename,...
                sigobj.shotno, sigobj.nodename);
            if isempty(cache_sig)
                % check if it's multiple nodes with same time dimension
                if isempty(sig_time)
                    sigobj.sigreadtime;
                else
                    sigobj.time = sig_time;
                    sigobj.timesliceindex = [];
                end
                sigobj.sigreaddata;
                cache_sig.time = sigobj.time;
                cache_sig.data = sigobj.data;
                sigobj.mdscache.cache_write(sigobj.treename,...
                    sigobj.shotno, sigobj.nodename, cache_sig);
            else
                sigobj.time = cache_sig.time;
                sigobj.data = cache_sig.data; 
            end
            sigobj.timesliceindex = timerngind(sigobj.time, time_range);
            sigobj.sigslice(time_range, 1);
        end
    end
    %% signal public methods
    methods
        function sigobj = signal(shotno, tree_name, node_name, varargin)
            %% create an instance of signal class
            %  sigobj = signal
            %  sigobj = signal(shotno)
            %  sigobj = signal(shotno, tree_name)
            %  sigobj = signal(shotno, tree_name, node_name)
            %  sigobj = signal(shotno, tree_name, node_name, 'ReadNow', 0
            %                  'TimeRange', [])
            Args = struct('ReadNow', 0, 'TimeRange', [], ...
                'UseCache', 0, 'CachePath', '');
            Args = parseArgs(varargin, Args, {'ReadNow','UseCache'});
            % call superclasss construction fun
            sigobj = sigobj@mds;
            % init mds cache
            sigobj.cache_option(Args.UseCache);
            sigobj.mdscache  = mdscache(Args.CachePath);
            if nargin > 0
                % check argin
                if nargin == 2
                    node_name = '';
                elseif nargin == 1
                    tree_name = '';
                    node_name = '';
                end
                % set attributes
                sigobj.shotno = shotno;
                sigobj.treename = lower(tree_name);
                sigobj.nodename = lower(node_name);
                sigobj.revisenodename;
                % read signal from mds server
                if ~isempty(Args.TimeRange)
                    Args.ReadNow = 1;
                end
                if Args.ReadNow
                    sigobj.sigread(Args.TimeRange);
                end
            end
        end
        function sigreadtime(sigobj, time_range, keep_time)
        %% read signal time from mds server
        % sigobj.sigreadtime(time_range)
            if nargin == 2
                keep_time = 0;
            elseif nargin == 1
                time_range = [];
                keep_time = 0;
            end
            if keep_time && ~isempty(sigobj.time)
                return
            end
            sigobj.revisenodename(1);
            tdi_exp = ['dim_of(\', sigobj.nodename, ')'];
            sigobj.time = sigobj.mdsread(tdi_exp);
            sigobj.timesliceindex = [1 length(sigobj.time)];
            if nargin == 2 && ~isempty(time_range)
                if ~isnumeric(time_range)
                    error('Argument "time_range" invalid!')
                end
                ind_rng = timerngind(sigobj.time, time_range);
                sigobj.time = sigobj.time(ind_rng(1):ind_rng(2));
                sigobj.timesliceindex = ind_rng;
            end
        end
        function sigreaddata(sigobj, index_range)
        %% read signal data from mds server
        % sigobj.sigreaddata
        % sigobj.sigreaddata(index_range)
            sigobj.revisenodename(1);
            % get slice range
            if nargin == 2 && ~isempty(index_range)
                if ~isnumeric(index_range)
                    error('Argument "index_range" invalid!')
                end
                ind_rng = sort(index_range);
                ind_rng = round(ind_rng([1 end]));
            elseif ~isempty(sigobj.timesliceindex)
                ind_rng = sigobj.timesliceindex([1 end]);
            else
                total_len = sigobj.mdslen;
                ind_rng = [1 total_len];
            end
            % read data dimension
            data_dims = sigobj.mdsdims;
            % gen slice string
            slice_str = '[';
            for i = 1:(length(data_dims)-1)
                slice_str = [slice_str, ','];
            end
            slice_str = [slice_str,...
                num2str(ind_rng(1)-1), ':',...
                num2str(ind_rng(2)-1),']'];
            % read data
            tdi_exp = ['data(\', sigobj.nodename, ')',slice_str];
            sigobj.data = sigobj.mdsread(tdi_exp);
            % transpose data if necessary
            if size(sigobj.data, 2) == 1 &&...
                    ndims(sigobj.data) == 2 &&...
                    size(sigobj.data, 1) > 1
                sigobj.data = sigobj.data';
            end
        end
        function sigread(sigobj, time_range)
        %% read signal with time and data
        % sigobj.sigread
        % sigobj.sigread(time_range)
        
            % check arguments in
            if nargin == 1
                time_range = [];
            end
            %% single node name
            sigobj.revisenodename;
            if ischar(sigobj.nodename)
                if sigobj.cache_option
                    sigobj.load_cache(time_range);
                else
                    sigobj.sigreadtime(time_range);
                    sigobj.sigreaddata;
                end
                return
            end
            %% multiple node names
            nodename_list = sigobj.nodename;
            % read first node
            sigobj.nodename = nodename_list{1};
            if sigobj.cache_option
                first_cache_sig = sigobj.load_cache(time_range);
            else
                sigobj.sigreadtime(time_range);
                sigobj.sigreaddata;
            end
            % allocate variable
            len_nodelist  = length(nodename_list);
            total_len  = length(sigobj.time);
            data_array = zeros(len_nodelist, total_len);
            data_array(1,:) = sigobj.data;
            nodename_list_new{1} = sigobj.nodename;
            % read remain nodes
            for i = 2:len_nodelist
                sigobj.nodename = nodename_list{i};
                if sigobj.cache_option
                    sigobj.load_cache(time_range, first_cache_sig.time); % avoid reading time again
                else
                    sigobj.sigreaddata;
                end
                if total_len ~= length(sigobj.data)
                    error(['node "', sigobj.nodename, '" has different length!']);
                end
                data_array(i,:) = sigobj.data;
                nodename_list_new{end+1} = sigobj.nodename;
            end
            % store properties
            sigobj.data = data_array;
            sigobj.nodename = nodename_list_new;
        end
        function sigreadbunch(sigobj, node_format_str, channel_list, time_range)
        %% read signal with multiple channels
        % sigobj.sigreadbunch(node_format_str, channel_list, time_range)
        % sigobj.sigreadbunch(node_format_str, channel_list)
        
            % check arguments
            if ~isnumeric(channel_list) || isempty(channel_list)
                error('Invalid argument "channel_list"!');
            end
            if nargin == 3
                time_range = [];
            end
            % gen nodename_list
            nodename_list = {};
            for i = 1:length(channel_list)
                nodename_list{end+1} = num2str(channel_list(i), node_format_str);
            end
            sigobj.nodename = nodename_list;
            % read signal
            sigobj.sigread(time_range);
        end
        function sigobj_copy = sigslice(sigobj, time_range, no_copy)
        %% slice and return a new copied signal
        % sliced_sigobj = sigobj.sigslice(time_range)
        % sliced_sigobj = sigobj.sigslice(time_range, no_copy)
            if nargin == 2
                no_copy = 0;
            end
            if ~no_copy
                sigobj_copy = sigobj.copy;
            end
            if isempty(time_range) || isequal(time_range, sigobj.time([1 end])) 
                return
            end
            ind_rng = timerngind(sigobj.time, time_range);
            tmp_time = sigobj.time(ind_rng(1):ind_rng(2));
            tmp_data = sigobj.sigpartdata(time_range);
            if no_copy
                sigobj.time = tmp_time;
                sigobj.data = tmp_data;
            else
                sigobj_copy.time = tmp_time;
                sigobj_copy.data = tmp_data;
            end
        end
        function part_data = sigpartdata(sigobj, time_range)
        %% get a part of the data by time
        % part_data = sigobj.sigpartdata(time_range)
            sigobj.sigdatacheck;
            if length(time_range) == 1
                time_ind = findtime(sigobj.time, time_range);
                ind_rng = [time_ind time_ind];
            elseif length(time_range) == 2
                ind_rng = timerngind(sigobj.time, time_range);
            else
                error('Invalid time_range!')
            end            
            part_data = arrayslice(sigobj.data, ndims(sigobj.data), ind_rng(1):ind_rng(2));
        end
        function unbund_data = sigunbund(sigobj, node_name)
        %% unbundle data by node name
        % unbund_data = sigobj.sigunbund(node_name)
            % single node_name
            if ischar(sigobj.nodename) && isequal(sigobj.nodename, lower(node_name))
                unbund_data = sigobj.data;
                return
            end
            % extract and find bunch data
            [found, index] = haselement(lower(sigobj.nodename), lower(node_name));
            if ~found
                error(['Node name: "' node_name '" not found!']);
            end
            unbund_data = sigobj.data(index, :);
        end
        function sigplot(sigobj, varargin)
        %% plot signal
        % sigobj.sigplot
        % sigobj.sigplot(...
        %          'HoldOn', 0,...
        %          'xlabel', '',...
        %          'ylabel', '',...
        %          'title', '',...
        %          'xlim', [],...
        %          'ylim', [],...
        %          'LineSpec', '',...
        %          'Legend', '');
            varargin = revvarargin(varargin, 'Legend', sigobj.nodename);
            x = sigobj.time;
            y = sigobj.data;
            varplot(x, y, varargin)
        end
        function cache(sigobj, option)
            if nargin == 1
                option = double(~sigobj.cache_option);
            end
            if ~isempty(option) && (isnumeric(option) && option || ischar(option) && strcmpi(option, 'on'))
                sigobj.cache_option(1);
                disp('cache is turned on')
            else
                sigobj.cache_option(0);
                disp('cache is turned off')
            end
        end
    end
end

