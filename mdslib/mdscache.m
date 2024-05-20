%% Class to cache mdsplus data for mdslib
% -------------------------------------------------------------------------
% Copyright 2019-2024 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
classdef mdscache < handle
    properties(Access=protected)
        cache_path
        clean_warning = 1;
    end
    
    methods(Access=protected)
        function data_path = locate_datapath(self, tree_name, shotno)
            shotno_str = num2str(shotno);
            data_path = chkdir(self.cache_path, tree_name, shotno_str);
        end
        
        function [bool, datafile_path] = existdata(~, data_path, node_name)
            datafile_path = fullfile(data_path,[node_name '.mat']);
            bool = exist(datafile_path, 'file');
        end
    end
    
    methods
        function self = mdscache(cache_path)
            default_cache = fullfile(getuserdir, 'mdscache');
            if nargin == 0
                cache_path = default_cache;
            end
            if isempty(cache_path)
                cache_path = default_cache;
            end
            try
                self.cache_path = chkdir(cache_path);
            catch
                error(['can not set cache_path with "' cache_path '"'])
            end
        end
        
        function cache_write(self, tree_name, shotno, node_name, data)
            data_path = self.locate_datapath(tree_name, shotno);
            [b, datafile_path] = self.existdata(data_path, node_name);
            if ~b
                mdsdata = data;
                save(datafile_path, 'mdsdata');
            end
        end
        
        function data = cache_read(self, tree_name, shotno, node_name)
            data_path = self.locate_datapath(tree_name, shotno);
            [b, datafile_path] = self.existdata(data_path, node_name);
            if b
                disp(['cache_read: ' datafile_path])
                load(datafile_path)
                data = mdsdata;
            else
                data = [];
            end
        end
        
        function cache_clean(self, varargin)
            path = self.cache_path;
            for i=1:length(varargin)
                tmp = varargin{i};
                if isnumeric(tmp)
                    tmp = num2str(tmp);
                end
                path = fullfile(path, tmp);
            end
            
            if exist(path, 'dir')
                if self.clean_warning
                    answer = input(['are you sure to clean all cache under : ' path '\n [y/n]'],'s');
                else
                    answer = 'y';
                end                
                if answer == 'y'
                    rmdir(path, 's');
                end
                return
            end

            if exist(path, 'file')
                if self.clean_warning
                    answer = input(['are you sure to delete "' path '"\n [y/n]'],'s');
                else
                    answer = 'y';
                end
                if answer == 'y'
                    delete(path);
                end
                return
            end
            
            warning(['not exist: ' path]);
        end
        
        function cache_clean_warning(self, show_warning)
            if nargin == 1
                show_warning = 1;
            end
            self.clean_warning = show_warning;
        end
        
        function res = global_cache(~, option)
            global global_caching
            if nargin == 2
                if ischar(option) 
                    if strcmpi(option, 'on')
                        option = true;
                    else
                        option = false;
                    end
                end
                global_caching = boolean(option);
                if global_caching
                    disp('mdscache: global caching is turned on!')
                end
            end
            if isempty(global_caching)
                global_caching = false;
            end
            res = global_caching;
        end
    end
end