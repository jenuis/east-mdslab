classdef (Abstract) freqinfo < basehandle
    %HRSSYS hold informations of hrs system
    %Derived from basehandle
    %   Props:
    %       shotno
    %       channelno
    %       freqlist
    %       bandwidth
    %   Methods
    %       fqobj.loadsyspara
    %       freq = fqobj.getfreq(channel_list)
    
    % Xiang Liu@ASIPP 2017-9-14
    % jent.le@hotmail.com
    
    properties
        channelno
        freqlist
        bandwidth
    end
    properties(Access = protected)
        parafilepath
    end
    
    methods
        function loadsyspara(fqobj)
        %% load system parameters
        % fqobj.loadsyspara
            fqobj.shotnocheck;
            if ~exist(fqobj.parafilepath, 'file')
                warning(['"' fqobj.parafilepath '" not found!'])
                return
            end
            load(fqobj.parafilepath);
            shot_sep_list = [freq_info{:,1}];
            tar_ind = findvaluefloor(shot_sep_list, fqobj.shotno);
            fqobj.freqlist = freq_info{tar_ind, 2};
            fqobj.channelno = 1:length(fqobj.freqlist);
            % remove bad channels
            try
                bad_channels = freq_info{tar_ind, 3};
            catch
                return
            end
            bad_channels = inrange([1 length(fqobj.freqlist)],...
                bad_channels);
            if ~isempty(bad_channels)
                fqobj.freqlist(bad_channels) = [];
                fqobj.channelno(bad_channels) = [];
            end
        end
        function freq = getfreq(fqobj, channel_list)
        %% extract freq from channel_list by channelno
        % freq = fqobj.getfreq(channel_list)
            if isempty(fqobj.freqlist)
                fqobj.loadsyspara;
            end
            [~, ~, all_in_range] = inrange(fqobj.channelno([1 end]),...
                channel_list);
            if ~all_in_range
                error('Some channel is out of range!');
            end
            ind = findvalue(fqobj.channelno, channel_list);
            freq = fqobj.freqlist(ind);
        end
    end
    
end
