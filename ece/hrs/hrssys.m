%% Subclass of ecefreqinfo for hrs of ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-14
% HRSSYS hold informations of hrs system
% Derived from ecefreqinfo
%   Props:
%       shotno
%       channelno
%       freqlist
%       bandwidth
%   Methods
%       self.loadsyspara
%       freq = self.getfreq(channel_list)
classdef hrssys < ecefreqinfo
    methods
        function self = hrssys(shotno)
            self.parafilepath = 'hrspara.mat';
            if nargin > 0
                self.shotno = shotno;
                self.loadsyspara;
            end
        end
    end
end