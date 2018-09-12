classdef misys < freqinfo
    %MISYS hold informations of mi system
    %Derived from freqinfo
    %   Props:
    %       shotno
    %       channelno
    %       freqlist
    %       bandwidth
    %   Methods
    %       msobj.loadsyspara
    %       freq = msobj.getfreq(channel_list)
    
    % Xiang Liu@ASIPP 2017-9-14
    % jent.le@hotmail.com
    
    methods
        function msobj = misys(shotno)
            msobj.parafilepath = 'mipara.mat';
            if nargin > 0
                msobj.shotno = shotno;
                msobj.loadsyspara;
            end
        end
    end
end