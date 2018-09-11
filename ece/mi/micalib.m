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
    
    properties(Constant, Access = protected)
        CalibFileName = fullfile('data', 'micf.mat');
    end
    
    methods
        function mcobj = micalib(shotno)
            mfile_dir = fileparts(mfilename('fullpath'));
            mcobj.cffilepath = fullfile(mfile_dir, mcobj.CalibFileName);
            if nargin > 0
                mcobj.shotno = shotno;
                mcobj.load;
            end
        end
    end
    
end

