classdef spectra < radte
    %SPECTRA class holds properties and methods of ECE spectra
    %Derived from radte
    %   Instance:
    %       sobj = spectra
    %       sobj = spectra(shotno, ece_type)
    %   Props:
    %       shotno
    %       ecetype
    %       freq
    %       time
    %       te
    %       err
    %    Instance:
    %       sobj.loadbymds(time_range)
    %       sobj.loadbycal(time_range)
    %       sobj.calspec(raw_sig, calib_factor)
    %       sobj.view(time_slice, varargin) check varplot for more details
    
    % Xiang Liu@ASIPP 2017-9-16
    % jent.le@hotmail.com
    
    properties
        freq
    end
    methods(Access = protected)
        function x = getxaxis(sobj)
            x = sobj.freq;
        end
    end
    methods
        function sobj = spectra(varargin)
                sobj = sobj@radte(varargin{:});
        end
        function loadbymds(sobj, time_range)
        %% read spectra data from mds server
        % pobj.loadbymds
        % pobj.loadbymds(time_range)
        
            % check arguments in
            if nargin == 1
                time_range = [];
            end
            sobj.check_load_args(time_range);
            
            % get a signal instance
            sig = signal;
            sig.shotno = sobj.shotno;
            sig.treename = sobj.TreeName;
            % read freq
            sig.nodename = ['freq_', sobj.ecetype];
            sig.sigreaddata;
            sobj.freq = sig.data;
            % read spectra
            sig.nodename = ['spec_', sobj.ecetype];
            sig.sigread(sobj.load_time_range);
            sobj.time = sig.time;
            sobj.spec = sig.data;
            % read spectra Error
            sig.nodename = [sig.nodename, 'err'];
            sig.sigreaddata;
            sobj.err = sig.data;
        end
        function loadbycal(sobj, time_range)
        %% calculate spectra by raw data
        % sobj.loadbycal
        % sobj.loadbycal(time_range)

            % check arguments
            if nargin == 1
                time_range = [];
            end
            sobj.check_load_args(time_range);

            % read shot para
            shot_para = shotpara(sobj.shotno);
            shot_para.readpulse;
            if isempty(sobj.load_time_range)
                time_slice = mean(shot_para.pulseflat);
            else
                time_slice = mean(sobj.load_time_range);
            end
            shot_para.read(time_slice);

            % collect system parameters
            switch sobj.ecetype
                case 'hrs'
                    raw_sig = hrsraw(sobj.shotno, 'tr', sobj.load_time_range);
                    calib_fac = hrscalib(sobj.shotno);
                case 'mi'
                    raw_sig = miraw(sobj.shotno);
                    calib_fac = micalib(sobj.shotno);
                otherwise
                    error('Unrecognized ece_type!')
            end
            sobj.calspec(raw_sig, calib_fac);        
        end
        function calspec(sobj, raw_sig, calib_factor)
        %% calculate spectra by raw signal and calibation factor
        % sobj.calspec(raw_sig, calib_factor)
            if raw_sig.shotno ~= calib_factor.shotno
                error('shotno of arguments mismatch!');
            end
            % set properties
            sobj.time = raw_sig.time;
            sobj.shotno = raw_sig.shotno;
            if isa(raw_sig, 'hrsraw')
                sobj.ecetype = 'hrs';
                sys_para = hrssys(sobj.shotno);
            elseif isa(raw_sig, 'miraw')
                sobj.ecetype = 'mi';
                sys_para = misys(sobj.shotno);
            else
                error('Invalid ece type for raw signal!');
            end
            % get valid channel list
            channel_list = raw_sig.channellist;
            % set freq property
            sobj.freq = sys_para.getfreq(channel_list);
            % extract calibration factor
            calib_factor = calib_factor.slicebychannel(channel_list);
            cf = calib_factor.cf;
            cf_err = calib_factor.err;
            % set te and err properties
            for i=1:length(channel_list)
                if isprop(raw_sig, 'background')
                    bg = raw_sig.background(i);
                else
                    bg = 0;
                end
                v_diff = raw_sig.data(i,:) - bg;
                sobj.te(i,:) = v_diff*cf(i);
                if isempty(cf_err)
                    continue
                end
                sobj.err(i,:) = v_diff*cf_err(i);
            end
        end
        function view(sobj, time_slice, varargin)
           % plot_title = [upper(sobj.ecetype) ' spectra for #'...
           %     num2str(sobj.shotno) ' @' num2str(time_slice,'%3.3f') 's'];
           plot_title = [' spectra for #' num2str(sobj.shotno)];
            varargin = revvarargin(varargin,...
                'XLabel','Frequency [GHz]',...
                'YLabel','Te [eV]',...
                'Title', plot_title);
            view@radte(sobj, time_slice, varargin);
        end
        function sortbyfreq(sobj)
            [sobj.freq, sort_ind] = sort(sobj.freq);
            if ~isempty(sobj.te)
                sobj.te = sobj.te(sort_ind, :);
            end
            if ~isempty(sobj.err)
                sobj.err = sobj.err(sort_ind, :);
            end
        end
    end
    
end

