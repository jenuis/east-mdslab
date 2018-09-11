classdef (Abstract) radte < basehandle
    %RADTE is a abstract class for ECE radiation Te
    %Derived from basehandle
    
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
    
    methods(Access = protected)
        function checkecetype(this)
            if isempty(this.ecetype) || ~haselement(radte.ECEType, this.ecetype)
                error('Attribute "ecetype" can either be "hrs" or "mi"!')
            end
        end
        function x = getxaxis(rdobj)
            error('Child class should overide this function!');
        end
    end
    methods
        function rdobj = radte(shotno, ece_type)
           if nargin > 0
                rdobj.shotno = shotno;
                rdobj.ecetype = lower(ece_type);
            end
        end
        function loadbymds
            error('Child class should overide this function!');
        end
        function loadbycal
            error('Child class should overide this function!');
        end
        function view(rdobj, time_slice, varargin)
            if length(time_slice) ~= 1
                error('Argument "time" should be a single value!');
            end
            if isempty(rdobj.te)
                error('te is empty!');
            end
            x = rdobj.getxaxis;
            [y, z] = rdobj.slice(time_slice);
            varargin = revvarargin(varargin, 'ErrData', z);
            varplot(x, y, varargin);
        end
        function [te_slice, err_slice] = slice(rdobj, time_range)
            ind_rng = timerngind(rdobj.time, time_range);
            te_slice = [];
            err_slice = [];
            if ~isempty(rdobj.te)
                te_slice = rdobj.te(:, ind_rng(1):ind_rng(2));
            end
            if ~isempty(rdobj.err)
                err_slice = rdobj.err(:, ind_rng(1):ind_rng(2));
            end
        end
    end
    
end

