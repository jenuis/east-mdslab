%% Subclass of calibfactor implemented for hrs of ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% XiangLiu@ASIPP 2017-9-14
% HRSCALIB load calibration factor of hrs system
% Derived from calibfactor
%   Props:
%       shotno
%       cf
%       err
%   Methods:
%      hcobj.load 
%      newobj = hcobj.slicebychannel(channel_list) 
classdef hrscalib < calibfactor
    methods
        function hcobj = hrscalib(shotno, calib_dir)
            if nargin < 2
                calib_dir = [];
            end
            hcobj.cffilepath = fullfile(calib_dir, 'hrscf.mat');
            if nargin > 0
                hcobj.shotno = shotno;
                hcobj.load;
            end
        end
    end
    
end

