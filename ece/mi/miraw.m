%% Class to read raw data for mi of ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-15
% MIRAW reads MI reference and interferogram and do fft get raw data
% Derived from signal
%   Instance:
%       self = miraw
%       self = miraw(shotno, 'TimeRange', time_range,...
%                     'ChannelList', channel_list)
%   Props:
%       refer
%       interfer
%       channellist
%   Methods:
%       self.mireadmds('TimeRange', time_range,...
%                       'ChannelList', channel_list)    
classdef miraw < signal
    properties
        refer
        interfer
        channellist
    end
    
    properties(Constant, Access = protected)
        TreeName = 'mpi_east';
        ReferNode = 'MPI_refer';
        InterferNode = 'MPI_interfer';
    end
    
    methods(Access = protected)
        function calinterfer(self)
            [self.data, ~ ,self.time] = micalinterfer(...
                self.refer.data, self.interfer.data);
            if ~isempty(self.channellist)
                self.data = self.data(self.channellist, :);
            end
        end
    end
    
    methods
        function self = miraw(shotno, varargin)
            if nargin > 0
                self.shotno = shotno;
                self.mireadmds(varargin);
            end
        end
        
        function mireadmds(self, varargin)
        %% read mi raw data from mds server
        % self.mireadmds
        % self.mireadmds('TimeRange', time_range,...
        %                 'ChannelList', channel_list)
            if length(varargin) == 1 && iscell(varargin{1})
                varargin = varargin{:};
            end
            mi_para = misys(self.shotno); 
            Args = struct(...
                'ChannelList', [],...
                'TimeRange',[]);
            Args = parseArgs(varargin, Args);
            if isempty(self.channellist)
                if ~isempty(Args.ChannelList)
                    self.channellist = Args.ChannelList;
                elseif ~isempty(mi_para.channelno)
                    self.channellist = mi_para.channelno;
                end
            end
            self.refer = signal(self.shotno, self.TreeName,...
                self.ReferNode, 'tr', Args.TimeRange, 'rn');
            self.interfer = signal(self.shotno, self.TreeName,...
                self.InterferNode, 'tr', Args.TimeRange, 'rn');
            self.calinterfer;
        end
    end
end

