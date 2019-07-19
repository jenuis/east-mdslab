classdef (Abstract) mdsbase < handle
    %MDSBASE is an abstract class for holding common methods 
    %Derived from handle
    %   Props:
    %       shotno
    %   Methods:
    %       new = copy(inst)
    
    properties
        shotno
    end
    
    methods
    %% public methods
        function new = copy(inst, omit_props)
        %% deep copy of a instance
            if nargin == 1
                omit_props = {};
            end
            if ischar(omit_props)
                omit_props = {omit_props};
            end
        
            % Instantiate new object of the same class.
            new = feval(class(inst));
 
            % Copy all non-hidden properties.
            p = properties(inst);
            for i = 1:length(p)
                if ~haselement(omit_props, p{i})
                    new.(p{i}) = inst.(p{i});
                end
            end
        end
    end
    methods(Static)
    %% static methods
    end
    methods(Access = protected)
    %% private methods
        function shotnocheck(inst)
            if ~isnumeric(inst.shotno)
                error('shotno is not a numeric type!')
            end
            if inst.shotno <= 0
                error('shotno should be a positive number!')
            end
        end
    end
end

