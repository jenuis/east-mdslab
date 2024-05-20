%% Class to read signal for mdslib
% -------------------------------------------------------------------------
% Copyright 2019-2024 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-12
%SIGNAL class which bundles time and data properties of a mds signal
%Derived from mds and mdsbase
%   Instance:
%       self = signal
%       self = signal(shotno)
%       self = signal(shotno, tree_name)
%       self = signal(shotno, tree_name, node_name)
%       self = signal(shotno, tree_name, node_name, 'ReadNow', 0,...
%                       'TimeRange', [])
%   Props:
%       shotno
%       treename
%       nodename: can be a string and a cell string of same time dimension
%                 under same tree.
%       time
%       data
%   Methods (inherited from mds):
%       data = self.mdsread(tdi_exp, disp_option)
%       data_len = self.mdslen
%       dims = self.mdsdims(disp_option)
%       curr_shot = self.mdscurrentshot
%   Methods:
%       self.sigreadtime(time_range)
%       self.sigreaddata(index_range)
%       self.sigread(time_range)
%       self.sigreadbunch(node_format_str, channel_list, time_range)
%       self_sliced = self.sigslice(time_range)
%       part_data = self.sigpartdata(time_range)
%       unbund_data = self.sigunbund(node_name)
%       self.sigplot
    
classdef signal < mds & mdsbase
    %% signal private properties
    properties(Access = protected)
        timesliceindex
        mdscache
        disp_option = 1
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
        function [data, status] = mdsread(self, tdi_exp, disp_option)
            %% inherited from mds class
            % data = self.mdsread(tdi_exp)
            % data = self.mdsread(tdi_exp, disp_option)
            if nargin < 3
                disp_option = 1;
            end
            [data, status] = mdsread@mds(self, self.shotno, self.treename, tdi_exp, disp_option);
        end
        
        function [data_len, status] = mdslen(self)
            %% inherited from mds class
            % data_len = self.mdslen
            mdsobj = mds; % must call mdsread within mds instance
            [data_len, status] = mdslen@mds(mdsobj, self.shotno, self.treename, self.nodename);
        end
        
        function [dims, status] = mdsdims(self, disp_option)
            %% inherited from mds class
            % dims = self.mdsdims
            % dims = self.mdsdims(disp_option)
            if nargin < 2
                disp_option = 1;
            end
            mdsobj = mds; % must call mdsread within mds instance
            [dims, status] = mdsdims@mds(mdsobj, self.shotno, self.treename, self.nodename, disp_option);
        end
    end
    
    %% signal private methods
    methods(Access = protected)
        %% overide mds private methods
        function revisenodename(self, single_node)
        %% inherited from mds class
            if nargin == 1
                single_node = 0;
            end
            self.nodename = revisenodename@mds(self, self.nodename);
            if iscellstr(self.nodename) && length(self.nodename) == 1
                self.nodename = self.nodename{1};
            end
            if single_node && ~ischar(self.nodename)
                error('One nodename check is on with more than one node!');
            end
        end
        
        %% private methods
        function sigdatacheck(self)
            % check if data is empty
            if isempty(self.data) || ~isnumeric(self.data)
                error('signal data is empty!')
            end
            % check if data has same time dimension with time
            shape = size(self.data);
            if shape(end) ~= length(self.time)
                error('data has different length with time dimension!')
            end
        end
        
        function cache_sig = load_cache(self, time_range, sig_time)
            if nargin == 2
                sig_time = [];
            elseif nargin == 1
                time_range = [];
                sig_time = [];
            end
            cache_sig = self.mdscache.cache_read(self.treename,...
                self.shotno, self.nodename);
            if isempty(cache_sig)
                % check if it's multiple nodes with same time dimension
                if isempty(sig_time)
                    self.sigreadtime;
                else
                    self.time = sig_time;
                    self.timesliceindex = [];
                end
                self.sigreaddata;
                cache_sig.time = self.time;
                cache_sig.data = self.data;
                self.mdscache.cache_write(self.treename,...
                    self.shotno, self.nodename, cache_sig);
            else
                self.time = cache_sig.time;
                self.data = cache_sig.data; 
            end
            self.timesliceindex = timerngind(self.time, time_range);
            self.sigslice(time_range, 1);
        end
    end
    
    %% signal public methods
    methods
        function self = signal(shotno, tree_name, node_name, varargin)
            %% create an instance of signal class
            %  self = signal
            %  self = signal(shotno)
            %  self = signal(shotno, tree_name)
            %  self = signal(shotno, tree_name, node_name)
            %  self = signal(shotno, tree_name, node_name, 'ReadNow', 0
            %                  'TimeRange', [])
            Args = struct('ReadNow', 0, 'TimeRange', [], ...
                'CachePath', '');
            Args = parseArgs(varargin, Args, {'ReadNow'});
            % call superclasss construction fun
            self = self@mds;
            % init mdscache
            self.mdscache  = mdscache(Args.CachePath);
            if nargin > 0
                % check argin
                if nargin == 2
                    node_name = '';
                elseif nargin == 1
                    tree_name = '';
                    node_name = '';
                end
                % set attributes
                self.shotno = shotno;
                self.treename = lower(tree_name);
                self.nodename = lower(node_name);
                self.revisenodename;
                % read signal from mds server
                if ~isempty(Args.TimeRange)
                    Args.ReadNow = 1;
                end
                if Args.ReadNow
                    self.sigread(Args.TimeRange);
                end
            end
        end
        
        function flag = is_signal_time_valid(self)
            self.revisenodename(1);
            tdi_exp = ['size(dim_of(\', self.nodename, '))'];
            time_len = self.mdsread(tdi_exp);
            data_shape = self.mdsdims();
            if find(data_shape == time_len)
                flag = true;
                return
            end
            flag = false;
        end
        
        function sigreadtime(self, time_range, keep_time)
        %% read signal time from mds server
        % self.sigreadtime(time_range)
            if nargin == 2
                keep_time = 0;
            elseif nargin == 1
                time_range = [];
                keep_time = 0;
            end
            if keep_time && ~isempty(self.time)
                return
            end
            self.revisenodename(1);
            tdi_exp = ['dim_of(\', self.nodename, ')'];
            self.time = self.mdsread(tdi_exp, self.disp_option);
            self.timesliceindex = [1 length(self.time)];
            if nargin == 2 && ~isempty(time_range)
                if ~isnumeric(time_range)
                    error('Argument "time_range" invalid!')
                end
                ind_rng = timerngind(self.time, time_range);
                self.time = self.time(ind_rng(1):ind_rng(2));
                self.timesliceindex = ind_rng;
            end
        end
        
        function sigreaddata(self, index_range)
        %% read signal data from mds server
        % self.sigreaddata
        % self.sigreaddata(index_range)
            self.revisenodename(1);
            % get slice range
            if nargin == 2 && ~isempty(index_range)
                if ~isnumeric(index_range)
                    error('Argument "index_range" invalid!')
                end
                ind_rng = sort(index_range);
                ind_rng = round(ind_rng([1 end]));
            elseif ~isempty(self.timesliceindex)
                ind_rng = self.timesliceindex([1 end]);
            else
                total_len = self.mdslen;
                ind_rng = [1 total_len];
            end
            % read data dimension
            data_dims = self.mdsdims(self.disp_option);
            % gen slice string
            slice_str = '[';
            for i = 1:(length(data_dims)-1)
                slice_str = [slice_str, ','];
            end
            slice_str = [slice_str,...
                num2str(ind_rng(1)-1), ':',...
                num2str(ind_rng(2)-1),']'];
            % read data
            tdi_exp = ['data(\', self.nodename, ')',slice_str];
            self.data = self.mdsread(tdi_exp, self.disp_option);
            % transpose data if necessary
            if size(self.data, 2) == 1 &&...
                    ndims(self.data) == 2 &&...
                    size(self.data, 1) > 1
                self.data = self.data';
            end
        end
        
        function sigread(self, time_range, time_check)
        %% read signal with time and data
        % self.sigread
        % self.sigread(time_range)
        
            % check arguments in
            if nargin < 3
                time_check = true;
            end
            if nargin == 1
                time_range = [];
            end      
            %% single node name
            self.revisenodename;
            if ischar(self.nodename)
                if self.cache()
                    self.load_cache(time_range);
                    return
                end
                
                if self.is_signal_time_valid()
                    self.sigreadtime(time_range);
                    self.sigreaddata;
                    return
                end
                
                msg = '"self.time" has different size with "self.data"!';
                if time_check
                    error(msg);
                end
                
                warning(msg);
                if ~isempty(time_range)
                    warning('"time_range" is set to empty!')
                end
                self.sigreadtime();
                self.sigreaddata([1 self.mdslen]);
                return
            end
            %% multiple node names
            nodename_list = self.nodename;
            % read first node
            self.nodename = nodename_list{1};
            if self.cache()
                first_cache_sig = self.load_cache(time_range);
            else
                dispoption = self.disp_option;
                dispstat('','init');
                self.disp_option = 2;
                self.sigreadtime(time_range);
                self.sigreaddata;
            end
            % allocate variable
            len_nodelist  = length(nodename_list);
            total_len  = length(self.time);
            data_array = zeros(len_nodelist, total_len);
            data_array(1,:) = self.data;
            nodename_list_new{1} = self.nodename;
            % read remain nodes
            for i = 2:len_nodelist
                self.nodename = nodename_list{i};
                if self.cache()
                    self.load_cache(time_range, first_cache_sig.time); % avoid reading time again
                else
                    self.sigreaddata;
                end
                if total_len ~= length(self.data)
                    error(['node "', self.nodename, '" has different length!']);
                end
                data_array(i,:) = self.data;
                nodename_list_new{end+1} = self.nodename;
            end
            % store properties
            self.data = data_array;
            self.nodename = nodename_list_new;
            if ~self.cache()
                self.disp_option = dispoption;
            end
            dispstat('','clean');
        end
        
        function sigreadbunch(self, node_format_str, channel_list, time_range)
        %% read signal with multiple channels
        % self.sigreadbunch(node_format_str, channel_list, time_range)
        % self.sigreadbunch(node_format_str, channel_list)
        
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
            self.nodename = nodename_list;
            % read signal
            self.sigread(time_range);
        end
        
        function self_sliced = sigslice(self, time_range, no_copy)
        %% slice and return a new copied signal
        % self_sliced = self.sigslice(time_range)
        % self_sliced = self.sigslice(time_range, no_copy)
            if nargin == 2
                no_copy = 0;
            end
            if ~no_copy
                self_sliced = self.copy;
            end
            if isempty(time_range) || isequal(time_range, self.time([1 end])) 
                return
            end
            ind_rng = timerngind(self.time, time_range);
            tmp_time = self.time(ind_rng(1):ind_rng(2));
            tmp_data = self.sigpartdata(time_range);
            if no_copy
                self.time = tmp_time;
                self.data = tmp_data;
            else
                self_sliced.time = tmp_time;
                self_sliced.data = tmp_data;
            end
        end
        
        function part_data = sigpartdata(self, time_range)
        %% get a part of the data by time
        % part_data = self.sigpartdata(time_range)
            self.sigdatacheck;
            if length(time_range) == 1
                time_ind = findtime(self.time, time_range);
                ind_rng = [time_ind time_ind];
            elseif length(time_range) == 2
                ind_rng = timerngind(self.time, time_range);
            else
                error('Invalid time_range!')
            end            
            part_data = arrayslice(self.data, ndims(self.data), ind_rng(1):ind_rng(2));
        end
        
        function unbund_data = sigunbund(self, node_name)
        %% unbundle data by node name
        % unbund_data = self.sigunbund(node_name)
            % single node_name
            if ischar(self.nodename) && isequal(self.nodename, lower(node_name))
                unbund_data = self.data;
                return
            end
            % extract and find bunch data
            [found, index] = haselement(lower(self.nodename), lower(node_name));
            if ~found
                error(['Node name: "' node_name '" not found!']);
            end
            unbund_data = self.data(index, :);
        end
        
        function sigplot(self, varargin)
        %% plot signal
        % self.sigplot
        % self.sigplot(...
        %          'HoldOn', 0,...
        %          'xlabel', '',...
        %          'ylabel', '',...
        %          'title', '',...
        %          'xlim', [],...
        %          'ylim', [],...
        %          'LineSpec', '',...
        %          'Legend', '');
            varargin = revvarargin(varargin, 'Legend', self.nodename);
            x = self.time;
            y = self.data;
            varplot(x, y, varargin)
        end
        
        function res = cache(self, varargin)
            res = self.mdscache.global_cache(varargin{:});
        end
        
        function setdisp(self, option)
            self.disp_option = option;
        end
        
        function [fs, dt] = getfs(self)
            time_diff = diff(self.time);
            assert(abs(sum(diff(time_diff)))<=time_diff(1)*1e-3, 'time not uniform!');
            dt = mean(time_diff);
            fs = 1/dt;
        end
    end
end

