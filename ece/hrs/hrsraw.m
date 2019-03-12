classdef hrsraw < signal
    %HRSRAW is a class to read hrs raw data derived from signal class
    %Derived from signal
    %   Instance:
    %       hrobj = hrsraw
    %       hrobj = hrsraw(shotno)
    %       hrobj = hrsraw(shotno, 'ReadHigh', 0,...
    %                      'ChannelList', [],...
    %                      'TimeRange', []))
    %   Props:
    %       channellist
    %   Methods
    %       hrobj.hrsreadmds('ReadHigh', 0,...
    %                        'ChannelList', [],...
    %                        'TimeRange', [])
    %       hrobj.hrsreadlocal
    %       sig_ch = hrobj.hrsgetchannel(channel_no)
    
    % Xiang Liu@ASIPP 2017-9-13
    % jent.le@hotmail.com
    
    properties(Constant, Access = protected)
        ChannelFormatStr = 'hrs%02ih';
        BgTimeRange = [-0.2 0];
    end
    properties
        channellist
        background
    end
    
    methods
        function hrobj = hrsraw(shotno, varargin)
            if nargin > 0
                hrobj.shotno = shotno;
                hrobj.hrsreadmds(varargin);
            end
        end
        function hrsreadmds(hrobj, varargin)
        %% read hrs raw data from mds server
        % hrobj.hrsreadmds('ReadHigh', 0,...
        %                  'ChannelList', [],...
        %                  'TimeRange', [])
            if length(varargin) == 1 && iscell(varargin{1})
                varargin = varargin{:};
            end
            hrs_para = hrssys(hrobj.shotno);
            Args = struct(...
                'ReadHigh', 0,...
                'ChannelList', [],...
                'TimeRange',[]);
            Args = parseArgs(varargin, Args, {'ReadHigh'});
            if isempty(hrobj.channellist)
                if ~isempty(Args.ChannelList)
                    hrobj.channellist = Args.ChannelList;
                elseif ~isempty(hrs_para.channelno)
                    hrobj.channellist = hrs_para.channelno;
                end
            end
            if Args.ReadHigh
                hrobj.treename = 'east';
            else
                hrobj.treename = 'east_1';
            end
            hrobj.sigreadbunch(...
                hrobj.ChannelFormatStr,...
                hrobj.channellist, Args.TimeRange);
            bg_noise = signal(hrobj.shotno, hrobj.treename,hrobj.nodename,...
                 'tr', hrobj.BgTimeRange, 'rn');
            hrobj.background = mean(bg_noise.data, 2);
        end
        function hrsreadlocal(hrobj)
        end
        function sig_ch = hrsgetchannel(hrobj, channel_no)
        %% extract a signal for a single channel
        % sig_ch = hrobj.hrsgetchannel(channel_no)
            channel_name = num2str(channel_no,  hrobj.ChannelFormatStr);
            sig_ch = signal(hrobj.shotno, hrobj.treename, channel_name);
            sig_ch.time = hrobj.time;
            sig_ch.data = hrobj.sigunbund(channel_name);
        end
    end
    
end

