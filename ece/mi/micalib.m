%% Subclass of ececalibfactor for mi of ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% XiangLiu@ASIPP 2017-9-14    
% MICALIB load calibration factor of mi system
% Derived from ececalibfactor
%   Props:
%       shotno
%       cf
%       err
%   Methods:
%      self.load 
%      self_new = self.slicebychannel(channel_list) 
classdef micalib < ececalibfactor
    methods
        function self = micalib(shotno, calib_dir)
            if nargin < 2
                calib_dir = [];
            end
            self.cffilepath = fullfile(calib_dir, 'micf.mat');
            if nargin > 0
                self.shotno = shotno;
                self.load;
            end
        end
    end
    
end

