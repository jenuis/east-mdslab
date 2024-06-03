%% Class holding calibration factor for ece
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% XiangLiu@ASIPP 2017-9-14
% ECECALIBFACTOR load calibration factor of ece system
% Derived from mdsbase
%   Props:
%       shotno
%       cf
%       err
%   Methods:
%      self.load 
%      self_new = self.slicebychannel(channel_list) 
classdef (Abstract) ececalibfactor < mdsbase    
    properties
        cf % calibration factor
        err % clibration error
    end
    
    properties(Access = protected)
        cffilepath
    end
    
    methods
        function load(self)
        %% load calibration factor by shotno
        % self.load
            shot_no = self.shotno;
            self.shotnocheck;
            cal_fac = matread(self.cffilepath, 'cal_fac');
            shot_sep_list = [cal_fac{:,1}];
            tar_ind = findvaluefloor(shot_sep_list, shot_no);
            self.cf = cal_fac{tar_ind, 2};
            self.err = cal_fac{tar_ind, 3};
            disp(num2str(cal_fac{tar_ind, 1}, 'ECE calib factor was loaded with [%i].'))
        end
        
        function self_new = slicebychannel(self, channel_list)
        %% slice cabration factor by channel_list
        % self_new = self.slicebychannel(channel_list)
            if isempty(self.cf)
                self.load
            end
            [~, ~, all_in_range] = inrange([1 length(self.cf)], channel_list);
            if ~all_in_range
                error('Some channel is out of range!');
            end
            self_new = self.copy;
            self_new.cf = self_new.cf(channel_list);
            if ~isempty(self_new.err)
                self_new.err = self_new.err(channel_list);
            end
        end
        
        function modify(self, varargin)
            Args = struct(...
                'Delete', 0,...
                'OnlyThisShot', 0,...
                'Description', []);
            Args = parseArgs(varargin, Args, {'OnlyThisShot' 'Delete'});
            cal_fac = matread(self.cffilepath, 'cal_fac');
            cal_fac_org = cal_fac;
            shot_sep_list = [cal_fac{:,1}];
            shot_ind = find(shot_sep_list == self.shotno);
            if isempty(shot_ind) % add calibration factor
                cal_fac{end+1, 1} = self.shotno;
                cal_fac{end, 2} = self.cf;
                cal_fac{end, 3} = self.err;
                if ~isempty(Args.Description)
                    cal_fac{end, 4} = Args.Description;
                end
                if Args.OnlyThisShot
                    curr_shot_ind = findvaluefloor(shot_sep_list, self.shotno);
                    if isempty(curr_shot_ind)
                        curr_shot_ind = 1;
                    end
                    cal_fac(end+1, :) = cal_fac_org(curr_shot_ind, :);
                    cal_fac{end, 1} = self.shotno + 1;
                    cal_fac{end, 4} = cal_fac_org{curr_shot_ind, 1};
                end
                shot_sep_list = [cal_fac{:,1}];
                [~, sort_ind] = sort(shot_sep_list);
                cal_fac = cal_fac(sort_ind, :);
            else
                if Args.Delete % delete this calibration factor
                    cal_fac(shot_ind, :) = [];
                else % update this calibration factor
                    cal_fac{shot_ind, 2} = self.cf;
                    cal_fac{shot_ind, 3} = self.err;
                    if ~isempty(Args.Description)
                        cal_fac{shot_ind, 4} = Args.Description;
                end
                end
            end
            save(self.cffilepath, 'cal_fac');
        end
    end
    
end

