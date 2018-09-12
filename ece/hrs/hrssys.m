classdef hrssys < freqinfo
    %HRSSYS hold informations of hrs system
    %Derived from freqinfo
    %   Props:
    %       shotno
    %       channelno
    %       freqlist
    %       bandwidth
    %   Methods
    %       hsobj.loadsyspara
    %       freq = hsobj.getfreq(channel_list)
    
    % Xiang Liu@ASIPP 2017-9-14
    % jent.le@hotmail.com
    
    methods
        function hsobj = hrssys(shotno)
            hsobj.parafilepath = 'hrspara.mat';
            if nargin > 0
                hsobj.shotno = shotno;
                hsobj.loadsyspara;
            end
        end
    end
end