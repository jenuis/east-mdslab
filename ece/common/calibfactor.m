classdef (Abstract) calibfactor < basehandle
    %CALIBFACTOR load calibration factor of ece system
    %Derived from basehandle
    %   Props:
    %       shotno
    %       cf
    %       err
    %   Methods:
    %      cbobj.load 
    %      newobj = cbobj.slicebychannel(channel_list) 
          
    % XiangLiu@ASIPP 2017-9-14
    % jent.le@hotmail.com
    
    properties
        cf % calibration factor
        err % clibration error
    end
    properties(Access = protected)
        cffilepath
    end
    
    methods
        function load(cbobj)
        %% load calibration factor by shotno
        % cbobj.load
            shot_no = cbobj.shotno;
            cbobj.shotnocheck;
            load(cbobj.cffilepath);
            shot_sep_list = [cal_fac{:,1}];
            tar_ind = findvaluefloor(shot_sep_list, shot_no);
            cbobj.cf = cal_fac{tar_ind, 2};
            cbobj.err = cal_fac{tar_ind, 3};
        end
        function newobj = slicebychannel(cbobj, channel_list)
        %% slice cabration factor by channel_list
        % newobj = cbobj.slicebychannel(channel_list)
            if isempty(cbobj.cf)
                cbobj.load
            end
            [~, ~, all_in_range] = inrange([1 length(cbobj.cf)], channel_list);
            if ~all_in_range
                error('Some channel is out of range!');
            end
            newobj = cbobj.copy;
            newobj.cf = newobj.cf(channel_list);
            if ~isempty(newobj.err)
                newobj.err = newobj.err(channel_list);
            end
        end
        function modify(cbobj, varargin)
            Args = struct(...
                'Delete', 0,...
                'OnlyThisShot', 0,...
                'Description', []);
            Args = parseArgs(varargin, Args, {'OnlyThisShot' 'Delete'});
            load(cbobj.cffilepath);
%             save([cbobj.cffilepath '.bak'], 'cal_fac'); % backup calibration file
            cal_fac_org = cal_fac;
            shot_sep_list = [cal_fac{:,1}];
            shot_ind = find(shot_sep_list == cbobj.shotno);
            if isempty(shot_ind) % add calibration factor
                cal_fac{end+1, 1} = cbobj.shotno;
                cal_fac{end, 2} = cbobj.cf;
                cal_fac{end, 3} = cbobj.err;
                if ~isempty(Args.Description)
                    cal_fac{end, 4} = Args.Description;
                end
                if Args.OnlyThisShot
                    curr_shot_ind = findvaluefloor(shot_sep_list, cbobj.shotno);
                    if isempty(curr_shot_ind)
                        curr_shot_ind = 1;
                    end
                    cal_fac(end+1, :) = cal_fac_org(curr_shot_ind, :);
                    cal_fac{end, 1} = cbobj.shotno + 1;
                    cal_fac{end, 4} = cal_fac_org{curr_shot_ind, 1};
                end
                shot_sep_list = [cal_fac{:,1}];
                [~, sort_ind] = sort(shot_sep_list);
                cal_fac = cal_fac(sort_ind, :);
            else
                if Args.Delete % delete this calibration factor
                    cal_fac(shot_ind, :) = [];
                else % update this calibration factor
                    cal_fac{shot_ind, 2} = cbobj.cf;
                    cal_fac{shot_ind, 3} = cbobj.err;
                    if ~isempty(Args.Description)
                        cal_fac{shot_ind, 4} = Args.Description;
                end
                end
            end
            save(cbobj.cffilepath, 'cal_fac');
        end
    end
    
end

