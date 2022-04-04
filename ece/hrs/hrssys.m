%% Subclass of freqinfo for hrs of ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-14
% HRSSYS hold informations of hrs system
% Derived from freqinfo
%   Props:
%       shotno
%       channelno
%       freqlist
%       bandwidth
%   Methods
%       hsobj.loadsyspara
%       freq = hsobj.getfreq(channel_list)
classdef hrssys < freqinfo
    methods
        function hsobj = hrssys(shotno)
            hsobj.parafilepath = 'hrspara.mat';
            if nargin > 0
                hsobj.shotno = shotno;
                hsobj.loadsyspara;
            end
        end
    end
end