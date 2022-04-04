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
%       mrobj = miraw
%       mrobj = miraw(shotno, 'TimeRange', time_range,...
%                     'ChannelList', channel_list)
%   Props:
%       refer
%       interfer
%       channellist
%   Methods:
%       mrobj.mireadmds('TimeRange', time_range,...
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
        function calinterfer(mrobj)
            [mrobj.data, ~ ,mrobj.time] = micalinterfer(...
                mrobj.refer.data, mrobj.interfer.data);
            if ~isempty(mrobj.channellist)
                mrobj.data = mrobj.data(mrobj.channellist, :);
            end
        end
    end
    methods
        function mrobj = miraw(shotno, varargin)
            if nargin > 0
                mrobj.shotno = shotno;
                mrobj.mireadmds(varargin);
            end
        end
        function mireadmds(mrobj, varargin)
        %% read mi raw data from mds server
        % mrobj.mireadmds
        % mrobj.mireadmds('TimeRange', time_range,...
        %                 'ChannelList', channel_list)
            if length(varargin) == 1 && iscell(varargin{1})
                varargin = varargin{:};
            end
            mi_para = misys(mrobj.shotno); 
            Args = struct(...
                'ChannelList', [],...
                'TimeRange',[]);
            Args = parseArgs(varargin, Args);
            if isempty(mrobj.channellist)
                if ~isempty(Args.ChannelList)
                    mrobj.channellist = Args.ChannelList;
                elseif ~isempty(mi_para.channelno)
                    mrobj.channellist = mi_para.channelno;
                end
            end
            mrobj.refer = signal(mrobj.shotno, mrobj.TreeName,...
                mrobj.ReferNode, 'tr', Args.TimeRange, 'rn');
            mrobj.interfer = signal(mrobj.shotno, mrobj.TreeName,...
                mrobj.InterferNode, 'tr', Args.TimeRange, 'rn');
            mrobj.calinterfer;
        end
        function mireadlocal(mrobj)
        end
    end
    
end

