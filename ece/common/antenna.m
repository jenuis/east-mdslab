classdef antenna
    %antenna Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static)
        function z = calz(r, shotno)
            z = (1.85-r)*tan(2.1*pi/180);
        end
    end
    
end

