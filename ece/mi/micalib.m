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
        function mcobj = micalib(shotno)
            mcobj.cffilepath = 'micf.mat';
            if nargin > 0
                mcobj.shotno = shotno;
                mcobj.load;
            end
        end
    end
    
end

