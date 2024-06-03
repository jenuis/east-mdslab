%% Raw signal reading class for hrs of ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-13
% HRSRAW is a class to read hrs raw data derived from signal class
% Derived from signal
%   Instance:
%       self = hrsraw
%       self = hrsraw(shotno)
%       self = hrsraw(shotno, 'ReadHigh', 0,...
%                      'ChannelList', [],...
%                      'TimeRange', []))
%   Props:
%       channellist
%   Methods
%       self.hrsreadmds('ReadHigh', 0,...
%                        'ChannelList', [],...
%                        'TimeRange', [])
%       self.hrsreadlocal
%       sig_ch = self.hrsgetchannel(channel_no)
classdef hrsraw < signal    
    properties(Constant, Access = protected)
        ChannelFormatStr = 'hrs%02ih';
        BgTimeRange = [-0.2 0];
    end
    
    properties
        channellist
        background
    end
    
    methods
        function self = hrsraw(shotno, varargin)
            if nargin > 0
                self.shotno = shotno;
                self.hrsreadmds(varargin);
            end
        end
        
        function hrsreadmds(self, varargin)
        %% read hrs raw data from mds server
        % self.hrsreadmds('ReadHigh', 0,...
        %                  'ChannelList', [],...
        %                  'TimeRange', [])
            if length(varargin) == 1 && iscell(varargin{1})
                varargin = varargin{:};
            end
            hrs_para = hrssys(self.shotno);
            Args = struct(...
                'ReadHigh', 0,...
                'ChannelList', [],...
                'TimeRange',[]);
            Args = parseArgs(varargin, Args, {'ReadHigh'});
            if isempty(self.channellist)
                if ~isempty(Args.ChannelList)
                    self.channellist = Args.ChannelList;
                elseif ~isempty(hrs_para.channelno)
                    self.channellist = hrs_para.channelno;
                else
                    error('Can not load system info automatically, please specify "ChannelList"!')
                end
            end
            if Args.ReadHigh
                self.treename = 'east';
            else
                self.treename = 'east_1';
            end
            self.sigreadbunch(...
                self.ChannelFormatStr,...
                self.channellist, Args.TimeRange);
            bg_noise = signal(self.shotno, self.treename,self.nodename,...
                 'tr', self.BgTimeRange, 'rn');
            self.background = mean(bg_noise.data, 2);
        end
        
        function sig_ch = hrsgetchannel(self, channel_no)
        %% extract a signal for a single channel
        % sig_ch = self.hrsgetchannel(channel_no)
            channel_name = num2str(channel_no,  self.ChannelFormatStr);
            sig_ch = signal(self.shotno, self.treename, channel_name);
            sig_ch.time = self.time;
            sig_ch.data = self.sigunbund(channel_name);
        end
    end
end

