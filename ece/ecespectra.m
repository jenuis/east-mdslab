%% Subclass of radte implemeted to get spectra for ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-16
% SPECTRA class holds properties and methods of ECE spectra
% Derived from radte
%   Instance:
%       self = ecespectra
%       self = ecespectra(shotno, ece_type)
%   Props:
%       shotno
%       ecetype
%       freq
%       time
%       te
%       err
%    Instance:
%       self.loadbymds(time_range)
%       self.loadbycal(time_range)
%       self.calspec(raw_sig, calib_factor)
%       self.view(time_slice, varargin) check varplot for more details
classdef ecespectra < radte
    properties
        freq
    end
    
    methods(Access = protected)
        function x = getxaxis(self)
            x = self.freq;
        end
    end
    
    methods
        function self = ecespectra(varargin)
                self = self@radte(varargin{:});
        end
        
        function loadbymds(self, time_range)
        %% read spectra data from mds server
        % self.loadbymds
        % self.loadbymds(time_range)
        
            % check arguments in
            if nargin == 1
                time_range = [];
            end
            self.check_load_args(time_range);
            
            % get a signal instance
            sig = signal;
            sig.shotno = self.shotno;
            sig.treename = self.TreeName;
            % read freq
            sig.nodename = ['freq_', self.ecetype];
            sig.sigreaddata;
            self.freq = sig.data;
            % read spectra
            sig.nodename = ['spec_', self.ecetype];
            sig.sigread(self.load_time_range);
            self.time = sig.time;
            self.spec = sig.data;
            % read spectra Error
            sig.nodename = [sig.nodename, 'err'];
            sig.sigreaddata;
            self.err = sig.data;
        end
        
        function loadbycal(self, time_range)
        %% calculate spectra by raw data
        % self.loadbycal
        % self.loadbycal(time_range)

            % check arguments
            if nargin == 1
                time_range = [];
            end
            self.check_load_args(time_range);

            % read shot para
            shot_para = shotpara(self.shotno);
            shot_para.readpulse;
            if isempty(self.load_time_range)
                time_slice = mean(shot_para.pulseflat);
            else
                time_slice = mean(self.load_time_range);
            end
            shot_para.read(time_slice);

            % collect system parameters
            switch self.ecetype
                case 'hrs'
                    raw_sig = hrsraw(self.shotno, 'tr', self.load_time_range);
                    calib_fac = hrscalib(self.shotno);
                case 'mi'
                    raw_sig = miraw(self.shotno);
                    calib_fac = micalib(self.shotno);
                otherwise
                    error('Unrecognized ece_type!')
            end
            self.calspec(raw_sig, calib_fac);        
        end
        
        function calspec(self, raw_sig, calib_factor)
        %% calculate spectra by raw signal and calibation factor
        % self.calspec(raw_sig, calib_factor)
            if raw_sig.shotno ~= calib_factor.shotno
                error('shotno of arguments mismatch!');
            end
            % set properties
            self.time = raw_sig.time;
            self.shotno = raw_sig.shotno;
            if isa(raw_sig, 'hrsraw')
                self.ecetype = 'hrs';
                sys_para = hrssys(self.shotno);
            elseif isa(raw_sig, 'miraw')
                self.ecetype = 'mi';
                sys_para = misys(self.shotno);
            else
                error('Invalid ece type for raw signal!');
            end
            % get valid channel list
            channel_list = raw_sig.channellist;
            % set freq property
            self.freq = sys_para.getfreq(channel_list);
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
                self.te(i,:) = v_diff*cf(i);
                if isempty(cf_err)
                    continue
                end
                self.err(i,:) = v_diff*cf_err(i);
            end
        end
        
        function view(self, time_slice, varargin)
           % plot_title = [upper(self.ecetype) ' spectra for #'...
           %     num2str(self.shotno) ' @' num2str(time_slice,'%3.3f') 's'];
           plot_title = [' spectra for #' num2str(self.shotno)];
            varargin = revvarargin(varargin,...
                'XLabel','Frequency [GHz]',...
                'YLabel','Te [eV]',...
                'Title', plot_title);
            view@radte(self, time_slice, varargin);
        end
        
        function sortbyfreq(self)
            [self.freq, sort_ind] = sort(self.freq);
            if ~isempty(self.te)
                self.te = self.te(sort_ind, :);
            end
            if ~isempty(self.err)
                self.err = self.err(sort_ind, :);
            end
        end
    end
    
end

