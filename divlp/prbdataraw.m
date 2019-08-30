classdef prbdataraw < prbcoeff & signal
    properties
        phy_type
    end
    methods
        function inst = prbdataraw(varargin)
            inst = inst@prbcoeff(varargin{:});
            inst.treename = 'east_1';
        end
        
        function prb_switch_tree(inst)
            if isequal(inst.treename, 'east_1')
                inst.treename = 'east';
            else
                inst.treename = 'east_1';
            end
            disp(['Will use "' inst.treename '" to load Div-LP data!'])
        end
        
        function prb_read(inst, probe_type, time_range)
            %% check arguments
            if nargin == 2
                time_range = [];
            end
            inst.phy_type = inst.check_prbtype(probe_type);
            %% get channel_list
            channel_list = inst.prb_extract_distinfo('channel'); 
            %% read coeff
            coeff = inst.prb_extract_coeff(inst.phy_type);
            if isempty(coeff)
                warning('load coefficient failed, no coefficient will be applied!');
                coeff = ones(1,length(channel_list));
            end           
            %% read noise
            format_str = [inst.check_postag() inst.phy_type '%02i'];
            inst.sigreadbunch(format_str, channel_list, [-2 0]);
            noise = mean(inst.data,2);
            %% read data
            inst.sigreadbunch(format_str, channel_list, time_range);
            for i=1:length(noise)
                inst.data(i,:) = (inst.data(i,:)-noise(i))*coeff(i);
            end
        end
    end
end