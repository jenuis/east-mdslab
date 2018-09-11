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
    
    properties(Constant, Access = protected)
    %% override constants
        ParaFileName = fullfile('data', 'mipara.mat');
    end
    
    methods
        function msobj = misys(shotno)
            mfile_dir = fileparts(mfilename('fullpath'));
            msobj.parafilepath = fullfile(mfile_dir, msobj.ParaFileName);
            if nargin > 0
                msobj.shotno = shotno;
                msobj.loadsyspara;
            end
        end
    end
end