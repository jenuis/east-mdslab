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
    
    properties(Constant, Access = protected)
        CalibFileName = fullfile('data', 'hrscf.mat');
    end
    
    methods
        function hcobj = hrscalib(shotno)
            mfile_dir = fileparts(mfilename('fullpath'));
            hcobj.cffilepath = fullfile(mfile_dir, hcobj.CalibFileName);
            if nargin > 0
                hcobj.shotno = shotno;
                hcobj.load;
            end
        end
    end
    
end

