classdef (Abstract) basehandle < handle
    %BASEHANDLE is an abstract class for holding common methods 
    %Derived from handle
    %   Props:
    %       shotno
    %   Methods:
    %       new = copy(this)
    
    properties
        shotno
    end
    
    methods
    %% public methods
        function new = copy(this, omit_props)
        %% deep copy of a instance
            if nargin == 1
                omit_props = {};
            end
            if ischar(omit_props)
                omit_props = {omit_props};
            end
        
            % Instantiate new object of the same class.
            new = feval(class(this));
 
            % Copy all non-hidden properties.
            p = properties(this);
            for i = 1:length(p)
                if ~haselement(omit_props, p{i})
                    new.(p{i}) = this.(p{i});
                end
            end
        end
    end
    methods(Static)
    %% static methods
    end
    methods(Access = protected)
    %% private methods
        function shotnocheck(this)
            if isempty(this.shotno)
                error('property "shotno" is empty!');
            end
        end
    end
end

