%% Class radation temperature for ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% RADTE is a abstract class for ECE radiation Te
% Derived from mdsbase
classdef (Abstract) radte < mdsbase
    properties
        ecetype
        time
        te
        err
    end
    
    properties(Constant, Access = protected)
        TreeName = 'analysis';
        ECEType = {'hrs','mi'};
    end
    
    properties(Access = protected)
        load_time_range
    end
    
    methods(Access = protected)
        function checkecetype(this)
            if isempty(this.ecetype) || ~haselement(radte.ECEType, this.ecetype)
                error('Attribute "ecetype" can either be "hrs" or "mi"!')
            end
        end
        
        function getxaxis(~)
            error('Child class should overide this function!');
        end
        
        function parse_load_time_range(self, time_range)
            if isempty(time_range)
                self.load_time_range = [];
                return
            end
            if length(time_range) == 1 || (max(time_range)-min(time_range)) < 0.1
                self.load_time_range = [-0.05 0.05] + mean(time_range);
                return
            end
            self.load_time_range = [min(time_range) max(time_range)];
        end
        
        function check_load_args(self, time_range)
            self.parse_load_time_range(time_range);
            self.shotnocheck;
            self.checkecetype;
        end
    end
    
    methods
        function self = radte(shotno, ece_type)
           if nargin > 0
                self.shotno = shotno;
                self.ecetype = lower(ece_type);
            end
        end
        
        function loadbymds(~)
            error('Child class should overide this function!');
        end
        
        function loadbycal(~)
            error('Child class should overide this function!');
        end
        
        function view(self, time_slice, varargin)
            if length(time_slice) ~= 1
                error('Argument "time" should be a single value!');
            end
            if isempty(self.te)
                error('te is empty!');
            end
            x = self.getxaxis;
            [y, z] = self.slice(time_slice);
            varargin = revvarargin(varargin, 'ErrData', z);
            varplot(x, y, varargin);
        end
        
        function [te_slice, err_slice] = slice(self, time_range)
            ind_rng = timerngind(self.time, time_range);
            te_slice = [];
            err_slice = [];
            if ~isempty(self.te)
                te_slice = self.te(:, ind_rng(1):ind_rng(2));
            end
            if ~isempty(self.err)
                err_slice = self.err(:, ind_rng(1):ind_rng(2));
            end
        end
    end
end

