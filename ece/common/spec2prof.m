%% Spectra to profile converting class for ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-14
% SPEC2PROF hold functions for mapping freqency to major radius
% Derived from mdsbase
%   Instance:
%       self = spec2prof
%   Props:
%       it
%       rmax
%       rmin
%       timeslice
%   Methods:
%       self.setpara(shot_para, time_slice)
%       radius = self.freq2radius(freq, n)
%       [radius_new, valid_ind] = self.validradius(radius)
%       [radius, valid_ind] = self.map2radius(freq)
classdef spec2prof < mdsbase    
    properties
        it
        rmax
        rmin
        timeslice
    end
    
    properties(Constant, Access = protected)
        MajorRadius = 1.85; % [m]
        MinorRadius = 0.45; % [m]
    end
    
    methods(Access = protected)
        function paracheck(self)
            if isempty(self.it) ||...
                    isempty(self.rmax) ||...
                    isempty(self.rmin) ||...
                    isempty(self.timeslice)
                error('key attributes not been properly set!')
            end 
        end
    end
    
    methods
        function self = spec2prof(shot_para, time_slice)
            if nargin > 0
                self.setpara(shot_para, time_slice);
            end
        end
        
        function setpara(self, shot_para, time_slice)
        %% set key parameters for mapping
        % self.setpara(shot_para, time_slice)
            if isempty(shot_para.rbdry) || ~isa(shot_para.rbdry, 'signal')...
                    || isempty(shot_para.rbdry.data)
                if isempty(self.rmax) || isempty(self.rmin)
                    warning('Set parameters error using efit, Not using default value instead!');
                    self.rmax = self.MajorRadius + self.MinorRadius;
                    self.rmin = self.MajorRadius - self.MinorRadius;
                end
                return
            end
            rbdry = shot_para.rbdry.sigslice(time_slice);
            self.rmin = rbdry.sigunbund('rbdrymin');
            self.rmax = rbdry.sigunbund('rbdrymax');
            if isempty(shot_para.it)
                error('shot_para.it is empty!')
            end
            self.it = shot_para.it.mean;
            self.timeslice = time_slice;
        end
        
        function radius = freq2radius(self, freq, n)
            if nargin == 2
                n = 2;
            end
            if isempty(self.it)
                error('"it" is empty!')
            end
            radius = 4.16e-4*abs(self.it)*28*n./freq;
        end
        
        function [radius_new, valid_ind] = validradius(self, radius)
        %% limit channels located inside LCFS and no harmonics overlap
        % [radius_new, valid_ind] = self.validradius(radius)
            [radius_new, valid_ind] = inrange(...
                [max(self.rmin, 2/3*self.rmax) self.rmax], radius);
        end
        
        function [radius, valid_ind] = map2radius(self, freq)
        %% mapping freqency to radius
        % [radius, valid_ind] = self.map2radius(freq)
            self.paracheck;
            radius = self.freq2radius(freq);
            [radius, valid_ind] = self.validradius(radius);
        end
    end
end
