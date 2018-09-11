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
    
    properties(Constant, Access = protected)
    %% override constants
        ParaFileName = fullfile('data', 'hrspara.mat');
    end
    
    methods
        function hsobj = hrssys(shotno)
            mfile_dir = fileparts(mfilename('fullpath'));
            hsobj.parafilepath = fullfile(mfile_dir, hsobj.ParaFileName);
            if nargin > 0
                hsobj.shotno = shotno;
                hsobj.loadsyspara;
            end
        end
    end
end