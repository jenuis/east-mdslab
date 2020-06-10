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
        function hcobj = hrscalib(shotno, calib_dir)
            if nargin == 1
                calib_dir = [];
            end
            hcobj.cffilepath = fullfile(calib_dir, 'hrscf.mat');
            if nargin > 0
                hcobj.shotno = shotno;
                hcobj.load;
            end
        end
    end
    
end

