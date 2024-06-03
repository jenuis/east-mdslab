%% Subclass of ecefreqinfo for mi of ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-14
% MISYS hold informations of mi system
% Derived from ecefreqinfo
%   Props:
%       shotno
%       channelno
%       freqlist
%       bandwidth
%   Methods
%       self.loadsyspara
%       freq = self.getfreq(channel_list)
classdef misys < ecefreqinfo
    methods
        function self = misys(shotno)
            self.parafilepath = 'mipara.mat';
            if nargin > 0
                self.shotno = shotno;
                self.loadsyspara;
            end
        end
    end
end