%% Subclass of freqinfo for mi of ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-14
% MISYS hold informations of mi system
% Derived from freqinfo
%   Props:
%       shotno
%       channelno
%       freqlist
%       bandwidth
%   Methods
%       msobj.loadsyspara
%       freq = msobj.getfreq(channel_list)
classdef misys < freqinfo
    methods
        function msobj = misys(shotno)
            msobj.parafilepath = 'mipara.mat';
            if nargin > 0
                msobj.shotno = shotno;
                msobj.loadsyspara;
            end
        end
    end
end