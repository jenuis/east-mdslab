classdef micalib < calibfactor
    %MICALIB load calibration factor of mi system
    %Derived from calibfactor
    %   Props:
    %       shotno
    %       cf
    %       err
    %   Methods:
    %      mcobj.load 
    %      newobj = mcobj.slicebychannel(channel_list) 
          
    % XiangLiu@ASIPP 2017-9-14
    % jent.le@hotmail.com
    
    methods
        function mcobj = micalib(shotno, calib_dir)
            if nargin == 1
                calib_dir = '.';
            end
            mcobj.cffilepath = fullfile(calib_dir, 'micf.mat');
            if nargin > 0
                mcobj.shotno = shotno;
                mcobj.load;
            end
        end
    end
    
end

