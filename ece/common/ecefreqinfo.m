%% Class holding system information for ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-14
% HRSSYS hold informations of hrs system
% Derived from mdsbase
%   Props:
%       shotno
%       channelno
%       freqlist
%       bandwidth
%   Methods
%       self.loadsyspara
%       freq = self.getfreq(channel_list)
classdef (Abstract) ecefreqinfo < mdsbase
    properties
        channelno
        freqlist
        bandwidth
    end
    
    properties(Access = protected)
        parafilepath
    end
    
    methods
        function loadsyspara(self)
        %% load system parameters
        % self.loadsyspara
            self.shotnocheck;
            if ~exist(self.parafilepath, 'file')
                warning(['"' self.parafilepath '" not found!'])
                return
            end
            freq_info = matread(self.parafilepath, 'freq_info');
            shot_sep_list = [freq_info{:,1}];
            tar_ind = findvaluefloor(shot_sep_list, self.shotno);
            self.freqlist = freq_info{tar_ind, 2};
            self.channelno = 1:length(self.freqlist);
            % remove bad channels
            try
                bad_channels = freq_info{tar_ind, 3};
            catch
                return
            end
            bad_channels = inrange([1 length(self.freqlist)],...
                bad_channels);
            if ~isempty(bad_channels)
                self.freqlist(bad_channels) = [];
                self.channelno(bad_channels) = [];
            end
        end
        
        function freq = getfreq(self, channel_list)
        %% extract freq from channel_list by channelno
        % freq = self.getfreq(channel_list)
            if isempty(self.freqlist)
                self.loadsyspara;
            end
            [~, ~, all_in_range] = inrange(self.channelno([1 end]),...
                channel_list);
            if ~all_in_range
                error('Some channel is out of range!');
            end
            ind = findvalue(self.channelno, channel_list);
            freq = self.freqlist(ind);
        end
    end
end
