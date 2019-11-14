classdef prbcoeff < prbbase
    properties(Access=protected)
        coeff_path;
        coeff_key;
        coeff_val;
        coeff_shotno;
    end
    methods(Access=protected)
        function coeff_path = check_coeffpath(inst, coeff_path)
            if nargin == 2
                inst.coeff_path = coeff_path;
            end
            if ~ischar(inst.coeff_path) || ~exist(inst.coeff_path, 'dir')
                error('invalid coeff_path!')
            end
            coeff_path = inst.coeff_path;
        end
    end
    methods
        function inst = prbcoeff(varargin)
            inst = inst@prbbase(varargin{:});
            if nargin >= 1
                inst.prb_load_coeff();
            end
        end
        
        function prb_set_coeff_path(inst, coeff_path)
            inst.check_coeffpath(coeff_path);
        end
        
        function prb_load_coeff(inst)
            %% check if coeff has already been loaded
            shotno = inst.check_shotno();
            if ~isempty(inst.coeff_shotno) && inst.coeff_shotno == shotno
                return
            end
            %% check coeff path
            coeff_dirs{1} = pwd;
            if isempty(inst.coeff_path)
                inst.coeff_path = fullfile(inst.read_config('user_path'), 'coefficient');
            end
            coeff_dirs{end+1} = inst.check_coeffpath();
            %% locate coeff file
            flag = 0;
            for i=1:length(coeff_dirs)
                coeff_dir = coeff_dirs{i};
                [shotlist, filelist] = foldershotlist(coeff_dir, '*.xlsx', 1:5);
                if isempty(shotlist)
                    continue
                end            
                [shotlist, sort_ind] = sort(shotlist);
                filelist = filelist(sort_ind);
                if shotno < shotlist(1)
                    continue
                end
                ind = find((shotlist - shotno) <= 0, 1, 'last');
                coeff_file = fullfile(coeff_dir, filelist{ind});
                flag = 1;
                break
            end
            if ~flag
                warning('could not find the coefficient file!')
                return
            end
            %% load coeff
            disp(['load div-prb coefficient: ' coeff_file '.xlsx'])
            [inst.coeff_val, inst.coeff_key] = xlsread(coeff_file);
            inst.coeff_shotno = shotno;
        end
        
        function [coeff, label] = prb_extract_coeff(inst, probe_type)
            %% check arguments
            coeff = [];
            label = {};
            if isempty(inst.coeff_val) || isempty(inst.coeff_key)
                return
            end
            probe_type = inst.check_prbtype(probe_type);
            position_tag = inst.check_postag();
            %% locate coeff by position_tag and phy_type
            ind = [];
            channel_list = [];
            for i=1:length(inst.coeff_key)
                tmp_key = lower(inst.coeff_key{i});
                if isequal(tmp_key(1:4), lower([position_tag probe_type]))
                    ind(end+1) = i;
                    channel_list(end+1) = str2double(inst.coeff_key{i}(end-1:end));
                end
            end
            if isempty(ind)
                warning('Coefficients not found!');
                return
            end
            %% locate by port_name
            channel_list_sel = inst.prb_extract_distinfo('channel');
            ind_sel = [];
            for i=1:length(channel_list_sel)
                ind_sel(end+1) = find(channel_list == channel_list_sel(i));
            end
            ind = ind(ind_sel);
            coeff = inst.coeff_val(ind);
            label = inst.coeff_key(ind);
            for i=1:length(coeff)
                if coeff(i)==0
                    coeff(i)=nan;
                end
            end
        end
    end
end