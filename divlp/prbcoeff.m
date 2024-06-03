%% Coefficients loader class for divlp
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2019-08-30
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
        function coeff_path = check_coeffpath(self, coeff_path)
            if nargin == 2
                self.coeff_path = coeff_path;
            end
            if ~ischar(self.coeff_path) || ~exist(self.coeff_path, 'dir')
                error('invalid coeff_path!')
            end
            coeff_path = self.coeff_path;
        end
    end
    
    methods
        function self = prbcoeff(varargin)
            self = self@prbbase(varargin{:});
            user_path = self.read_config('user_path');
            coeff_name = self.read_config('coeff_name');
            self.coeff_path = fullfile(user_path, coeff_name);
            if nargin >= 1
                self.prb_load_coeff();
            end
        end
        
        function coeff_path = prb_get_coeff_path(self)
            coeff_path = self.check_coeffpath();
        end
        
        function prb_set_coeff_path(self, coeff_path)
            self.check_coeffpath(coeff_path);
        end
        
        function coeff_filename = prb_get_coeff_filename(self)
            coeff_filename = '';
            if isempty(self.coeff_file)
                return
            end
            [~, coeff_filename] = fileparts(self.coeff_file);
        end
        
        function coeff = prb_load_coeff(self, shotno)
            %% check if coeff has already been loaded
            coeff.shotno = self.coeff_shotno;
            coeff.key = self.coeff_key;
            coeff.val = self.coeff_val;
            if nargin < 2
                shotno = self.check_shotno();
            end
            if ~isempty(self.shotno) && self.shotno == shotno && ~isempty(self.coeff_key) && ~isempty(self.coeff_val)
                return
            end
            %% check coeff path
%             coeff_dirs{1} = pwd;
            coeff_dirs = {};
            coeff_dirs{end+1} = self.check_coeffpath();
            %% locate coeff file
            flag = 0;
            for i=1:length(coeff_dirs)
                coeff_dir = coeff_dirs{i};
                [shotlist, filelist] = foldershotlist(coeff_dir, '*.xlsx');
                if isempty(shotlist)
%                     continue
                    [shotlist, filelist] = foldershotlist(coeff_dir, '*.FULL.mat');
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
                self.coeff_shotrng = shotlist(ind);
                if length(shotlist) < ind+1
                    self.coeff_shotrng(2) = inf;
                else
                    self.coeff_shotrng(2) = shotlist(ind+1);
                end
                break
            end
            if ~flag
                warning(['could not find the coefficient file for shotno = ' num2str(shotno) '!'])
                return
            end
            %% load coeff
            disp(['load div-prb coefficient: ' coefffile])
            status = xlsfinfo(coefffile);
            if isempty(status)
                assert(strcmpi(coefffile(end-3:end),'.mat'), 'file should be a mat file!');
                coeff = matread(coefffile, 'coeff');
                self.coeff_shotno = coeff.shotno;
                self.coeff_key = coeff.key;
                self.coeff_val = coeff.val;
            else
                [self.coeff_val, self.coeff_key] = xlsread(coefffile, 1, 'A1:B1000');
                [~, file_name] = fileparts(coefffile);
                self.coeff_shotno = str2double(file_name(1:5));
                coeff.shotno = self.coeff_shotno;
                coeff.key = self.coeff_key;
                coeff.val = self.coeff_val;
            end
            self.shotno = shotno;
            self.coeff_file = coefffile;
        end
        
        function prb_save_coeff(self, coeff, save2pwd)
            if nargin < 3
                save2pwd = 1;
            end
            coefffile = self.coeff_file;
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
        
        function revised_coeff_path = prb_load_revised_coeff(self, probe_type)
            if isempty(self.coeff_shotrng)
                error('call "prb_load_coeff" first!')
            end
            [shotlist, filelist] = foldershotlist(self.check_coeffpath(), ['*.' upper([self.check_postag() probe_type]) '*.mat']);
            if ~isempty(shotlist)
                [shotlist, sort_ind] = sort(shotlist);
                filelist = filelist(sort_ind);
                inds = shotlist >= min(self.coeff_shotrng) & shotlist < max(self.coeff_shotrng) & shotlist <= self.check_shotno();
                if sum(inds)
                    filelist = filelist(inds);
                    revised_coeff_path = filelist{end};
                    coeff = matread(revised_coeff_path, 'coeff');
                    self.coeff_val(coeff.inds_global) = coeff.val;
                    disp(['load revised div-prb coefficient: ' revised_coeff_path])
                end
            end
        end
        
        function [coeff, label] = prb_extract_coeff(self, probe_type)
            %% check arguments
            coeff = [];
            label = {};
            if isempty(self.coeff_val) || isempty(self.coeff_key)
                return
            end
            probe_type = self.check_prbtype(probe_type);
            position_tag = self.check_postag();
            %% load revised coeff by position_tag and phy_type
            self.prb_load_revised_coeff(probe_type);
            %% locate coeff by position_tag and phy_type
            ind = [];
            channel_list = [];
            for i=1:length(self.coeff_key)
                tmp_key = lower(self.coeff_key{i});
                if isequal(tmp_key(1:4), lower([position_tag probe_type]))
                    ind(end+1) = i;
                    channel_list(end+1) = str2double(self.coeff_key{i}(end-1:end));
                end
            end
            if isempty(ind)
                warning('Coefficients not found!');
                return
            end
            %% locate by port_name
            channel_list_sel = self.prb_extract_distinfo('channel');
            ind_sel = [];
            for i=1:length(channel_list_sel)
                ind_sel(end+1) = find(channel_list == channel_list_sel(i));
            end
            ind = ind(ind_sel);
            coeff = self.coeff_val(ind);
            label = self.coeff_key(ind);
            for i=1:length(coeff)
                if coeff(i)==0
                    coeff(i)=nan;
                end
            end
        end
    end
end