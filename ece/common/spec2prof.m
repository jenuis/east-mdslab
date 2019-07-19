classdef spec2prof < mdsbase
    %SPEC2PROF hold functions for mapping freqency to major radius
    %Derived from mdsbase
    %   Instance:
    %       spobj = spec2prof
    %   Props:
    %       it
    %       rmax
    %       rmin
    %       timeslice
    %   Methods:
    %       spobj.setpara(shot_para, time_slice)
    %       radius = spobj.freq2radius(freq, n)
    %       [radius_new, valid_ind] = spobj.validradius(radius)
    %       [radius, valid_ind] = spobj.map2radius(freq)
 
    % Xiang Liu@ASIPP 2017-9-14
    % jent.le@hotmail.com
    
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
        function paracheck(spobj)
            if isempty(spobj.it) ||...
                    isempty(spobj.rmax) ||...
                    isempty(spobj.rmin) ||...
                    isempty(spobj.timeslice)
                error('key attributes not been properly set!')
            end 
        end
    end
    methods
        function spobj = spec2prof(shot_para, time_slice)
            if nargin > 0
                spobj.setpara(shot_para, time_slice);
            end
        end
        function setpara(spobj, shot_para, time_slice)
        %% set key parameters for mapping
        % spobj.setpara(shot_para, time_slice)
            if isempty(shot_para.rbdry) || ~isa(shot_para.rbdry, 'signal')...
                    || isempty(shot_para.rbdry.data)
                if isempty(spobj.rmax) || isempty(spobj.rmin)
                    warning('Set parameters error using efit, Not using default value instead!');
                    spobj.rmax = spobj.MajorRadius + spobj.MinorRadius;
                    spobj.rmin = spobj.MajorRadius - spobj.MinorRadius;
                end
                return
            end
            rbdry = shot_para.rbdry.sigslice(time_slice);
            spobj.rmin = rbdry.sigunbund('rbdrymin');
            spobj.rmax = rbdry.sigunbund('rbdrymax');
            if isempty(shot_para.it)
                error('shot_para.it is empty!')
            end
            spobj.it = shot_para.it.mean;
            spobj.timeslice = time_slice;
        end
        function radius = freq2radius(spobj, freq, n)
            if nargin == 2
                n = 2;
            end
            if isempty(spobj.it)
                error('"it" is empty!')
            end
            radius = 4.16e-4*abs(spobj.it)*28*n./freq;
        end
        function [radius_new, valid_ind] = validradius(spobj, radius)
        %% limit channels located inside LCFS and no harmonics overlap
        % [radius_new, valid_ind] = spobj.validradius(radius)
            [radius_new, valid_ind] = inrange(...
                [max(spobj.rmin, 2/3*spobj.rmax) spobj.rmax], radius);
        end
        function [radius, valid_ind] = map2radius(spobj, freq)
        %% mapping freqency to radius
        % [radius, valid_ind] = spobj.map2radius(freq)
            spobj.paracheck;
            radius = spobj.freq2radius(freq);
            [radius, valid_ind] = spobj.validradius(radius);
        end
    end
    
end

