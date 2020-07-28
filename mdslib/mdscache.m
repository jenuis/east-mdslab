classdef mdscache < handle
    %% mds cache class, cache data locally
    properties(Access=protected)
        cache_path
        clean_warning = 1;
    end
    methods(Access=protected)
        function data_path = locate_datapath(inst, tree_name, shotno)
            shotno_str = num2str(shotno);
            data_path = chkdir(inst.cache_path, tree_name, shotno_str);
        end
        function [bool, datafile_path] = existdata(~, data_path, node_name)
            datafile_path = fullfile(data_path,[node_name '.mat']);
            bool = exist(datafile_path, 'file');
        end
    end
    methods
        function inst = mdscache(cache_path)
            default_cache = fullfile(getuserdir, 'mdscache');
            if nargin == 0
                cache_path = default_cache;
            end
            if isempty(cache_path)
                cache_path = default_cache;
            end
            try
                inst.cache_path = chkdir(cache_path);
            catch
                error(['can not set cache_path with "' cache_path '"'])
            end
        end
        function cache_write(inst, tree_name, shotno, node_name, data)
            data_path = inst.locate_datapath(tree_name, shotno);
            [b, datafile_path] = inst.existdata(data_path, node_name);
            if ~b
                mdsdata = data;
                save(datafile_path, 'mdsdata');
            end
        end
        function data = cache_read(inst, tree_name, shotno, node_name)
            data_path = inst.locate_datapath(tree_name, shotno);
            [b, datafile_path] = inst.existdata(data_path, node_name);
            if b
                disp(['cache_read: ' datafile_path])
                load(datafile_path)
                data = mdsdata;
            else
                data = [];
            end
        end
        function cache_clean(inst, varargin)
            path = inst.cache_path;
            for i=1:length(varargin)
                tmp = varargin{i};
                if isnumeric(tmp)
                    tmp = num2str(tmp);
                end
                path = fullfile(path, tmp);
            end
            
            if exist(path, 'dir')
                if inst.clean_warning
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
                if inst.clean_warning
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
        function cache_clean_warning(inst, show_warning)
            if nargin == 1
                show_warning = 1;
            end
            inst.clean_warning = show_warning;
        end
        function res = global_cache(inst, option)
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