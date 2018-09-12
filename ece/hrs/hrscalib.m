classdef hrscalib < calibfactor
    %HRSCALIB load calibration factor of hrs system
    %Derived from calibfactor
    %   Props:
    %       shotno
    %       cf
    %       err
    %   Methods:
    %      hcobj.load 
    %      newobj = hcobj.slicebychannel(channel_list) 
          
    % XiangLiu@ASIPP 2017-9-14
    % jent.le@hotmail.com
    
    methods
        function hcobj = hrscalib(shotno)
            hcobj.cffilepath = 'hrscf.mat';
            if nargin > 0
                hcobj.shotno = shotno;
                hcobj.load;
            end
        end
    end
    
end

