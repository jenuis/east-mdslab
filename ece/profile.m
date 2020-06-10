classdef profile < radte
    %PROFILE class holds properties and methods of ECE profile
    %Derived from radte
    %   Instance:
    %       pobj = profile
    %       pobj = profile(shotno, ece_type)
    %   Props:
    %       shotno
    %       ecetype
    %       radius
    %       z
    %       psinorm
    %       time
    %       te
    %       err
    %   Methods:
    %       pobj.loadbymds(time_range)
    %       pobj.loadbycal(time_range)
    %       pobj.calprof(spec, shot_para)
    %       pobj.view(time_slice, varargin) check varplot for more details
    
    % Xiang Liu@ASIPP 2017-9-16
    % jent.le@hotmail.com
    
    properties
        radius
        z
        psinorm
        channelno
    end
    
    methods(Access = protected)
        function x = getxaxis(pobj)
            x = pobj.radius;
        end
    end
    
    methods
        function pobj = profile(varargin)
            pobj = pobj@radte(varargin{:});
        end
        function loadbymds(pobj, time_range)
        %% read profile data from mds server
        % pobj.loadbymds
        % pobj.loadbymds(time_range)
        
            % check arguments in
            if nargin == 1
                time_range = [];
            end
            pobj.check_load_args(time_range);
            
            % get a signal instance
            sig = signal;
            sig.shotno = pobj.shotno;
            sig.treename = pobj.TreeName;
            % read major radius
            sig.nodename = ['r_', pobj.ecetype];
            sig.sigreaddata;
            pobj.radius = sig.data;
            % read vertical z
            sig.nodename = ['z_', pobj.ecetype];
            sig.sigreaddata;
            pobj.z = sig.data;
            % read Te
            sig.nodename = ['te_', pobj.ecetype];
            sig.sigread(pobj.load_time_range);
            pobj.time = sig.time;
            pobj.te = sig.data;
            % read Te Error
            sig.nodename = [sig.nodename, 'err'];
            sig.sigreaddata;
            pobj.err = sig.data;
        end
        function loadbycal(pobj, time_range, radius_range)
        %% calculate profile by raw data
        % pobj.loadbycal
        % pobj.loadbycal(time_range)
        
        % check arguments
        if nargin < 2
            time_range = [];
        end
        if nargin < 3
            radius_range = [0 inf];
        end
        pobj.check_load_args(time_range);
        
        % read shot para
        shot_para = shotpara(pobj.shotno);
        shot_para.read;
        if isempty(pobj.load_time_range)
            time_median = mean(shot_para.pulseflat);
        else
            time_median = mean(pobj.load_time_range);
        end
        
        % collect system parameters
        switch pobj.ecetype
            case 'hrs'
                sys_para = hrssys(pobj.shotno);
                calib_fac = hrscalib(pobj.shotno);
            case 'mi'
                sys_para = misys(pobj.shotno);
                calib_fac = micalib(pobj.shotno);
            otherwise
                error('Unrecognized ece_type!')
        end
        % set radius and get valid channels
        s2p = spec2prof(shot_para, time_median);
        [pobj.radius, valid_ind] = s2p.map2radius(sys_para.freqlist);
        radius_inds = pobj.radius <= max(radius_range) & ...
            pobj.radius >= min(radius_range) & ...
            ~isnan(calib_fac.cf(valid_ind));
        pobj.radius = pobj.radius(radius_inds);
        valid_ind = valid_ind(radius_inds);
        pobj.z = antenna.calz(pobj.radius);
        channel_list = sys_para.channelno(valid_ind);
        % collect raw data and calibration factor
        switch pobj.ecetype
            case 'hrs'
                raw_sig = hrsraw(pobj.shotno, 'tr', pobj.load_time_range,...
                    'cl', channel_list);
            case 'mi'
                raw_sig = miraw(pobj.shotno, 'cl', channel_list);
            otherwise
                error('Unrecognized ece_type!')
        end
        % calculate spectra
        spec = spectra(pobj.shotno, pobj.ecetype);
        spec.calspec(raw_sig, calib_fac);
        % set time, te and err
        pobj.time = spec.time;
        pobj.te = spec.te;
        pobj.err = spec.err;
        pobj.channelno = channel_list;
        end
        function calprof(pobj, spec, shot_para)
        %% calculate profile by spectra and shotpara
        % pobj.calprof(spec, shot_para)
            if spec.shotno ~= shot_para.shotno
                error('shotno of arguments mismatch!');
            end
            % set common properties
            pobj.ecetype = spec.ecetype;
            pobj.time = spec.time;
            pobj.shotno = spec.shotno;
            % set radius and get valid channels
            s2p = spec2prof(shot_para, mean(pobj.time));
            [pobj.radius, valid_ind] = s2p.map2radius(spec.freq);
            pobj.z = antenna.calz(pobj.radius);
            % set te and err
            pobj.te = spec.te(valid_ind, :);
            if ~isempty(spec.err)
            %if ~isempty(pobj.err)
                pobj.err = spec.err(valid_ind, :);
            end
            pobj.channelno = valid_ind;
        end
        function view(pobj, time_slice, varargin)
        %% view profile of sepecific time
        % pobj.viewprof(time_slice)
           % plot_title = [upper(pobj.ecetype) ' Te profile for #'...
           %     num2str(pobj.shotno) ' @' num2str(time_slice,'%3.3f') 's'];
            plot_title = [' Te profile for #' num2str(pobj.shotno)];
            varargin = revvarargin(varargin,...
                'XLabel','Major Radius [m]',...
                'YLabel','Te [eV]',...
                'Title', plot_title);
            view@radte(pobj, time_slice, varargin);
        end
        function sortbyradius(pobj)
            [pobj.radius, sort_ind] = sort(pobj.radius);
            if ~isempty(pobj.z)
                pobj.z = pobj.z(sort_ind);
            end
            if ~isempty(pobj.psinorm)
                pobj.psinorm = pobj.psinorm(sort_ind);
            end
            if ~isempty(pobj.te)
                pobj.te = pobj.te(sort_ind, :);
            end
            if ~isempty(pobj.err)
                pobj.err = pobj.err(sort_ind, :);
            end
            if ~isempty(pobj.channelno)
                pobj.channelno = pobj.channelno(sort_ind);
            end
        end
    end
    
end

