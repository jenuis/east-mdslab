%% Subclass of radte implemented to get profile distribution for ece
% -------------------------------------------------------------------------
% Copyright 2019-2024 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-16
% PROFILE class holds properties and methods of ECE profile
% Derived from radte
%   Instance:
%       self = eceprofile
%       self = eceprofile(shotno, ece_type)
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
%       self.loadbymds(time_range)
%       self.loadbycal(time_range)
%       self.calprof(spec, shot_para)
%       self.view(time_slice, varargin) check varplot for more details
classdef eceprofile < radte
    properties
        radius
        z
        psinorm
        channelno
    end
    
    methods(Access = protected)
        function x = getxaxis(self)
            x = self.radius;
        end
    end
    
    methods
        function self = eceprofile(varargin)
            self = self@radte(varargin{:});
        end
        
        function loadbymds(self, time_range, varargin)
        %% read profile data from mds server
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
            % read major radius
            sig.nodename = ['r_', self.ecetype];
            sig.sigreaddata;
            self.radius = sig.data;
            % read vertical z
            sig.nodename = ['z_', self.ecetype];
            sig.sigreaddata;
            self.z = sig.data;
            % read Te
            sig.nodename = ['te_', self.ecetype];
            sig.sigread(self.load_time_range);
            self.time = sig.time;
            self.te = sig.data;
            % read Te Error
            sig.nodename = [sig.nodename, 'err'];
            sig.sigreaddata;
            self.err = sig.data;
            % find channelno
            Args.ChannelList = [];
            Args.FrequencyList = [];
            Args = parseArgs(varargin, Args);
            if isempty(Args.ChannelList) || isempty(Args.FrequencyList)
                switch self.ecetype
                case 'hrs'
                    sys_para = hrssys(self.shotno);
                case 'mi'
                    sys_para = misys(self.shotno);
                otherwise
                    error('Unrecognized ece_type!')
                end
                channel_list = sys_para.channelno;
                frequency_list = sys_para.freqlist;
            else
                channel_list = Args.ChannelList;
                frequency_list =  Args.FrequencyList;
            end
            t = mean(self.time);
            shot_para = shotpara(self.shotno);
            shot_para.read(t+[-0.5 0.5]);
            s2p = spec2prof(shot_para, t);
            [pos_radius, valid_ind] = s2p.map2radius(frequency_list);
            channel_list = channel_list(valid_ind);
            for i=1:length(self.radius)
                ind = findvalue(pos_radius, self.radius(i));
                self.channelno(i) = channel_list(ind);
            end
        end
        
        function loadbycal(self, time_range, radius_range)
        %% calculate profile by raw data
        % self.loadbycal
        % self.loadbycal(time_range)
        
        % check arguments
        if nargin < 2
            time_range = [];
        end
        if nargin < 3
            radius_range = [0 inf];
        end
        self.check_load_args(time_range);
        
        % read shot para
        shot_para = shotpara(self.shotno);
        shot_para.read;
        if isempty(self.load_time_range)
            time_median = mean(shot_para.pulseflat);
        else
            time_median = mean(self.load_time_range);
        end
        
        % collect system parameters
        switch self.ecetype
            case 'hrs'
                sys_para = hrssys(self.shotno);
                calib_fac = hrscalib(self.shotno);
            case 'mi'
                sys_para = misys(self.shotno);
                calib_fac = micalib(self.shotno);
            otherwise
                error('Unrecognized ece_type!')
        end
        % set radius and get valid channels
        s2p = spec2prof(shot_para, time_median);
        [self.radius, valid_ind] = s2p.map2radius(sys_para.freqlist);
        radius_inds = self.radius <= max(radius_range) & ...
            self.radius >= min(radius_range);
        cf_inds = ~isnan(calib_fac.cf(valid_ind));
        if size(radius_inds, 1) ~= size(cf_inds, 1)
            cf_inds = cf_inds';
        end
        radius_inds = radius_inds & cf_inds;
        self.radius = self.radius(radius_inds);
        valid_ind = valid_ind(radius_inds);
        self.z = eceantenna.calz(self.radius);
        channel_list = sys_para.channelno(valid_ind);
        % collect raw data and calibration factor
        switch self.ecetype
            case 'hrs'
                raw_sig = hrsraw(self.shotno, 'tr', self.load_time_range,...
                    'cl', channel_list);
            case 'mi'
                raw_sig = miraw(self.shotno, 'cl', channel_list);
            otherwise
                error('Unrecognized ece_type!')
        end
        % calculate spectra
        spec = ecespectra(self.shotno, self.ecetype);
        spec.calspec(raw_sig, calib_fac);
        % set time, te and err
        self.time = spec.time;
        self.te = spec.te;
        self.err = spec.err;
        self.channelno = channel_list;
        end
        
        function calprof(self, spec, shot_para)
        %% calculate profile by ecespectra and shotpara
        % self.calprof(spec, shot_para)
            if spec.shotno ~= shot_para.shotno
                error('shotno of arguments mismatch!');
            end
            % set common properties
            self.ecetype = spec.ecetype;
            self.time = spec.time;
            self.shotno = spec.shotno;
            % set radius and get valid channels
            s2p = spec2prof(shot_para, mean(self.time));
            [self.radius, valid_ind] = s2p.map2radius(spec.freq);
            self.z = eceantenna.calz(self.radius);
            % set te and err
            self.te = spec.te(valid_ind, :);
            if ~isempty(spec.err)
            %if ~isempty(self.err)
                self.err = spec.err(valid_ind, :);
            end
            self.channelno = valid_ind;
        end
        
        function view(self, time_slice, varargin)
        %% view profile of sepecific time
        % self.viewprof(time_slice)
           % plot_title = [upper(self.ecetype) ' Te profile for #'...
           %     num2str(self.shotno) ' @' num2str(time_slice,'%3.3f') 's'];
            plot_title = [' Te profile for #' num2str(self.shotno)];
            varargin = revvarargin(varargin,...
                'XLabel','Major Radius [m]',...
                'YLabel','Te [eV]',...
                'Title', plot_title);
            view@radte(self, time_slice, varargin);
        end
        
        function sortbyradius(self)
            [self.radius, sort_ind] = sort(self.radius);
            if ~isempty(self.z)
                self.z = self.z(sort_ind);
            end
            if ~isempty(self.psinorm)
                self.psinorm = self.psinorm(sort_ind);
            end
            if ~isempty(self.te)
                self.te = self.te(sort_ind, :);
            end
            if ~isempty(self.err)
                self.err = self.err(sort_ind, :);
            end
            if ~isempty(self.channelno)
                self.channelno = self.channelno(sort_ind);
            end
        end
    end
end

