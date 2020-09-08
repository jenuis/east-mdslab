classdef prbcoeff < prbbase
    properties(Access=protected)
        coeff_path;
        coeff_file;
        coeff_shotno;
        coeff_key;
        coeff_val;
        coeff_shotrng;
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
            inst.coeff_path = fullfile(inst.read_config('user_path'), 'coeff');
            if nargin >= 1
                inst.prb_load_coeff();
            end
        end
        
        function coeff_path = prb_get_coeff_path(inst)
            coeff_path = inst.check_coeffpath();
        end
        
        function prb_set_coeff_path(inst, coeff_path)
            inst.check_coeffpath(coeff_path);
        end
        
        function coeff_filename = prb_get_coeff_filename(inst)
            coeff_filename = '';
            if isempty(inst.coeff_file)
                return
            end
            [~, coeff_filename] = fileparts(inst.coeff_file);
        end
        
        function coeff = prb_load_coeff(inst, shotno)
            %% check if coeff has already been loaded
            coeff.shotno = inst.coeff_shotno;
            coeff.key = inst.coeff_key;
            coeff.val = inst.coeff_val;
            if nargin < 2
                shotno = inst.check_shotno();
            end
            if ~isempty(inst.shotno) && inst.shotno == shotno && ~isempty(inst.coeff_key) && ~isempty(inst.coeff_val)
                return
            end
            %% check coeff path
%             coeff_dirs{1} = pwd;
            coeff_dirs = {};
            coeff_dirs{end+1} = inst.check_coeffpath();
            %% locate coeff file
            flag = 0;
            for i=1:length(coeff_dirs)
                coeff_dir = coeff_dirs{i};
%                 [shotlist, filelist] = foldershotlist(coeff_dir, '*.xlsx*', 1:5);
                [shotlist, filelist] = foldershotlist(coeff_dir, '*.xlsx', 1:5);
                if isempty(shotlist)
%                     continue
                    [shotlist, filelist] = foldershotlist(coeff_dir, '*.FULL.mat', 1:5);
                    if isempty(shotlist)
                        continue
                    end
                end            
                [shotlist, sort_ind] = sort(shotlist);
                filelist = filelist(sort_ind);
                if shotno < shotlist(1)
                    continue
                end
                ind = find((shotlist - shotno) <= 0, 1, 'last');
                coefffile = filelist{ind};
                flag = 1;
%                 if i == 1
%                     warning('Using coefficient in current dir!')
%                 end
                inst.coeff_shotrng = shotlist(ind);
                if length(shotlist) < ind+1
                    inst.coeff_shotrng(2) = inf;
                else
                    inst.coeff_shotrng(2) = shotlist(ind+1);
                end
                break
            end
            if ~flag
                warning('could not find the coefficient file!')
                return
            end
            %% load coeff
            disp(['load div-prb coefficient: ' coefffile])
            status = xlsfinfo(coefffile);
            if isempty(status)
                assert(strcmpi(coefffile(end-3:end),'.mat'), 'file should be a mat file!');
                load(coefffile);
                inst.coeff_shotno = coeff.shotno;
                inst.coeff_key = coeff.key;
                inst.coeff_val = coeff.val;
            else
                [inst.coeff_val, inst.coeff_key] = xlsread(coefffile, 1, 'A1:B1000');
                [~, file_name] = fileparts(coefffile);
                inst.coeff_shotno = str2double(file_name(1:5));
                coeff.shotno = inst.coeff_shotno;
                coeff.key = inst.coeff_key;
                coeff.val = inst.coeff_val;
            end
            inst.shotno = shotno;
            inst.coeff_file = coefffile;
        end
        
        function prb_save_coeff(inst, coeff, save2pwd)
            if nargin < 3
                save2pwd = 1;
            end
            coefffile = inst.coeff_file;
            status = xlsfinfo(coefffile);
            if ~isempty(status)
                coefffile = [coefffile '.mat'];
            end
            assert(strcmpi(coefffile(end-3:end),'.mat'), 'file should be a mat file!');
            [file_path, file_name] = fileparts(coefffile);
            coefffile = strrep(coefffile, file_name(1:5), num2str(coeff.shotno));
            if save2pwd
                coefffile = strrep(coefffile, file_path, pwd);
            end
            save(coefffile, 'coeff');
        end
        
        function prb_load_revised_coeff(inst, probe_type)
            if isempty(inst.coeff_shotrng)
                error('call "prb_load_coeff" first!')
            end
            [shotlist, filelist] = foldershotlist(inst.check_coeffpath(), ['*.' upper([inst.check_postag() probe_type]) '*.mat'], 1:5);
            if ~isempty(shotlist)
                [shotlist, sort_ind] = sort(shotlist);
                filelist = filelist(sort_ind);
                inds = shotlist >= min(inst.coeff_shotrng) & shotlist < max(inst.coeff_shotrng) & shotlist <= inst.check_shotno();
                if sum(inds)
                    filelist = filelist(inds);
                    load(filelist{end});
                    inst.coeff_val(coeff.inds_global) = coeff.val;
                    disp(['load revised div-prb coefficient: ' filelist{end}])
                end
            end
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
            %% load revised coeff by position_tag and phy_type
            inst.prb_load_revised_coeff(probe_type);
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