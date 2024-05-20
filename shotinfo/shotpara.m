%% Class to read shot parameters for mdslib 
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Xiang Liu@ASIPP 2017-9-12
%   Instance:
%       spobj = shotpara
%       spobj = shotpara(shotno)
%   Props:
%       shotno
%       pulseflat
%       it
%       bt
%       mftime
%       maxisloc
%       mfpsirz
%       mfgridrz
%       mfssi
%       mfpsinorm
%       rbdry
%   Methods:
%       spobj.read(time_range)
%       spobj.readpulse
%       spobj.readit
%       spobj.readmftime
%       spobj.readmaxis(time_range)
%       spobj.readmflux(time_range)
%       spobj.readrbdry(time_range)
%       spobj.calnormpsi(r, z, time_range)
%       spobj.calbt
%       spobj.viewmflux(time_slice)
classdef shotpara < mdsbase
    properties
    %% public properties
        EfitTree = 'efit_east';
        pulseflat
        it
        bt
        mftime
        maxisloc  % rmaxis, zmaxis
        mfpsirz   
        mfgridrz  % r, z
        mfssi     % ssimag, ssibry
        mfpsinorm
        rbdry     % rbdrymin, rbdrymax (not mds signal has no treename)
        mfbdryrz
        limiterrz
    end
    properties(Access = protected)
    %% protected properties 
        efit_status = nan;
    end
    properties(Constant, Access = protected)
    %% protected constant properties
        ItRange = [10500 3500]; % center and error
        PcsTree = 'pcs_east';
        IpNode = 'pcrl01';
        EfitTimeNode = 'atime';
        SsiMagNode = 'ssimag';
        SsiBryNode = 'ssibry';
        RMaxisNode = 'rmaxis';
        ZMaxisNode = 'zmaxis';
        PsiRZNode = 'psirz';
        GridRNode = 'r';
        GridZNode = 'z';
        RBdryMin = 'rbdrymin';
        RBdryMax = 'rbdrymax';
        BdryRZNode = 'bdry';
        LimiterNode = 'lim';
        DefaultRmajor =  1.85;
        DefaultRminor = 0.45;
        ItInfo = {...
            'east', 'focs_it';...
            'east', 'focs4';...
            'east', 'tfp';...
            'eng_tree', 'it';...
            'pcs_east', 'sysdrit';...
            };
    end
    methods(Access = protected)
    %% private methods
        function extract_it(spobj, sig_it, only_tail)
            if nargin == 2
                only_tail = 0;
            end
            if only_tail
                tmp = sig_it.data((end-10):end);
            else
                tmp = sig_it.data;
            end
            tmp_mean = mean(tmp);
            if abs(abs(tmp_mean)-spobj.ItRange(1)) > spobj.ItRange(2)
                return
            end
            spobj.it.mean = tmp_mean;
            spobj.it.nodename = sig_it.nodename;
        end
        function normalizepsi(spobj)
            spobj.mfpsinorm = spobj.mfpsirz.copy;
            psi_rz = spobj.mfpsirz.data;
            ssi_psi = spobj.mfssi;
            maxis_psi = ssi_psi.sigunbund(spobj.SsiMagNode);
            bdry_psi = ssi_psi.sigunbund(spobj.SsiBryNode);
            for i=1:length(maxis_psi)
                spobj.mfpsinorm.data(:,:,i) = (psi_rz(:,:,i) - maxis_psi(i))/(bdry_psi(i) - maxis_psi(i));
            end
        end
        function mfdatacheck(spobj)
            if isempty(spobj.mfpsinorm) || isempty(spobj.mfgridrz)
                error('Run readmflux first!');
            end
        end
        function time_range = mftimerngcheck(spobj, time_range, allow_single_value)
            if nargin == 2
                allow_single_value = 0;
            end
            if isempty(spobj.mftime)
                spobj.readmftime;
            end
            if isempty(time_range)
                time_range = spobj.mftime([1 end]);
            % ensure psirz has the third dim
            elseif length(time_range) == 1 && ~allow_single_value
                time_range = time_range + [0 0.1];
            end
        end
        function check_efit_status(spobj)
            m = mds;
            [~, spobj.efit_status] = m.mdsread(spobj.shotno, spobj.EfitTree, ['\' spobj.EfitTimeNode '[0]']);
        end
    end
    methods(Static)
        function bp = calbp(ip, a, kappa)
            %% change unit to SI
            if min(ip) < 20
                ip = ip*1e6;
                warning('Ip unit is asserted to be [MA]')
            elseif min(ip) < 20*1e3
                ip = ip*1e3;
                warning('Ip unit is asserted to be [kA]')
            end
            %% cal
            mu0 = 4*pi*1e-7;

            % bp = mu0*ip./(pi*a.*sqrt(2*(1+kappa.^2))); % goldston 2012 NF misses minor
            % radius, correct in Eich PRL

            L  = 2*pi*a.*sqrt((1+kappa.^2)/2);
            bp = mu0*ip./L;
        end
    end
    methods
        function spobj = shotpara(shotno)
        %% create an instance of shotpara
            if nargin > 0
                spobj.shotno = shotno;
            end
        end
        
        function read(spobj, time_range)
        %% read all properties
        % spobj.read
        % spobj.read(time_range)
            if nargin == 1
                time_range = [];
            end
            spobj.readpulse;
            spobj.readit;
            spobj.check_efit_status;
            if ~spobj.efit_status
                return
            end
            spobj.readmftime;
            spobj.readmaxis(time_range);
            spobj.readmflux(time_range);
            spobj.readrbdry(time_range);
        end
        
        function readpulse(spobj)
        %% get shot pulse range of flattop
        % spobj.readpulse
            if ~isempty(spobj.pulseflat)
                return
            end
            ip = signal(spobj.shotno, spobj.PcsTree, spobj.IpNode);
            ip.sigread;
            flat_range = flattop(ip.data);
            spobj.pulseflat = ip.time(flat_range);
        end
        
        function readit(spobj)
        %% read It
        % spobj.readit
            if ~isempty(spobj.it)
                return
            end
            sig_it = signal(spobj.shotno);
            for i=1:length(spobj.ItInfo)
                tree_name = spobj.ItInfo{i, 1};
                node_name = spobj.ItInfo{i, 2};
                sig_it.treename = tree_name;
                sig_it.nodename = node_name;
                try
                    sig_it.sigreaddata;
                    spobj.extract_it(sig_it);
                    if ~isempty(spobj.it)
                        break
                    end
                catch
%                     warning(['Failed read It from: "' tree_name '"->"' node_name '"']);
                end
            end           
        end
        
        function readmftime(spobj)
        %% read efit time
        % spobj.readmftime
            if ~isempty(spobj.mftime)
                return
            end
            if isnan(spobj.efit_status)
                spobj.check_efit_status;
            end
            if ~spobj.efit_status
                return
            end
            sig = signal(spobj.shotno, spobj.EfitTree, spobj.EfitTimeNode);
            sig.sigreaddata;
            spobj.mftime = sig.data;
        end
        
        function readmaxis(spobj, time_range)
        %% read location of magnetic axis
        % spobj.readmaxis
        % spobj.readmaxis(time_range)
            if nargin == 1
                time_range = [];
            end
            if isnan(spobj.efit_status)
                spobj.check_efit_status;
            end
            if ~spobj.efit_status
                return
            end
            time_range = spobj.mftimerngcheck(time_range);
            spobj.maxisloc = signal(spobj.shotno, spobj.EfitTree, {spobj.RMaxisNode, spobj.ZMaxisNode}, 'rn', 'tr', time_range);
        end
        
        function readmflux(spobj, time_range)
        %% read magnetic flux information from efit
        % spobj.readmflux
        % spobj.readmflux(time_range)
            if nargin == 1
                time_range = [];
            end
            if isnan(spobj.efit_status)
                spobj.check_efit_status;
            end
            if ~spobj.efit_status
                return
            end
            time_range = spobj.mftimerngcheck(time_range);
            spobj.mfpsirz = signal(spobj.shotno, spobj.EfitTree, spobj.PsiRZNode, 'tr', time_range, 'rn');
            spobj.mfgridrz = signal(spobj.shotno, spobj.EfitTree, {spobj.GridRNode, spobj.GridZNode}, 'rn');
            spobj.mfgridrz.time = [];
            spobj.mfssi = signal(spobj.shotno, spobj.EfitTree, {spobj.SsiMagNode, spobj.SsiBryNode}, 'tr', time_range, 'rn');
            spobj.normalizepsi;
        end
        
        function readrbdry(spobj, time_range)
        %% read min and max of major radius at LCFS
        % spobj.readrbdry
        % spobj.readrbdry(time_range)
            spobj.mfdatacheck;
            if isempty(spobj.maxisloc)
                error('Run readmaxis first!')
            end
            if nargin == 1
                time_range = [];
            end
            if isnan(spobj.efit_status)
                spobj.check_efit_status;
            end
            if ~spobj.efit_status
                return
            end
            time_range = spobj.mftimerngcheck(time_range);
            psirz_norm = spobj.mfpsinorm.sigslice(time_range);
            grid_r = spobj.mfgridrz.sigunbund(spobj.GridRNode);
            grid_z = spobj.mfgridrz.sigunbund(spobj.GridZNode);
            maxis_loc = spobj.maxisloc.sigpartdata(time_range);
            r_maxis = maxis_loc(1,:);
            z_maxis = maxis_loc(2,:);
            spobj.rbdry = signal(spobj.shotno, '', {spobj.RBdryMin, spobj.RBdryMax});
            spobj.rbdry.time = psirz_norm.time;
            for i = 1:length(spobj.rbdry.time)
                zmaxis_ind = findvalue(grid_z, z_maxis(i));
                rmaxis_ind = findvalue(grid_r, r_maxis(i));
                psirz_norm_mid = psirz_norm.data(:, zmaxis_ind, i);
                tmp = interp1(psirz_norm_mid(1:rmaxis_ind), grid_r(1:rmaxis_ind), 1, 'pchip');
                tmp(2) = interp1(psirz_norm_mid(rmaxis_ind:end), grid_r(rmaxis_ind:end), 1, 'pchip');
                spobj.rbdry.data(:, i) = sort(tmp);
            end
        end
        
        function readmfbdryrz(spobj, time_range)
        %% read the RZ location of LCFS
        % spobj.readrbdry
        % spobj.readrbdry(time_range)
            if nargin == 1
                time_range = [];
            end
            if isnan(spobj.efit_status)
                spobj.check_efit_status;
            end
            if ~spobj.efit_status
                return
            end
            time_range = spobj.mftimerngcheck(time_range);
            spobj.mfbdryrz = signal(spobj.shotno, spobj.EfitTree, spobj.BdryRZNode, 'rn', 'tr', time_range);
        end
        
        function readlimiter(spobj)
            s = signal(spobj.shotno, spobj.EfitTree, spobj.LimiterNode, 'rn');
            spobj.limiterrz = s.data;
        end
        
        function norm_psi = calnormpsi(spobj, r, z, time_range)
        %% calculate normlized psi by (r,z) location
        % orm_psi = spobj.calnormpsi(r, z)
        % orm_psi = spobj.calnormpsi(r, z, time_range)
            spobj.mfdatacheck;
            if nargin == 3
                time_range = [];
            end
            time_range = spobj.mftimerngcheck(time_range, 1);
            if size(r,1) ~= 1
                r = r';
            end
            if size(z,1) ~= 1
                z = z';
            end
            psirz_norm = spobj.mfpsinorm.sigslice(time_range);
            grid_r = spobj.mfgridrz.sigunbund(spobj.GridRNode);
            grid_z = spobj.mfgridrz.sigunbund(spobj.GridZNode);
            norm_psi = signal(spobj.shotno);
            norm_psi.time = psirz_norm.time;
            norm_psi.data = [];
            for i = 1:length(norm_psi.time)
                norm_psi.data(:, i) = interp2(grid_r, grid_z, psirz_norm.data(:,:,i)', r, z, 'spline'); % don't forget to transform psirz_norm.data
            end
        end
        
        function calbt(spobj, time_range)
            if isempty(spobj.it)
                error('Run readit firtst!')
            end
            if isa(spobj.maxisloc, 'signal')
                if nargin == 1
                    time_range = spobj.maxisloc.time([1 end]);
                end
                rmaxis_slice = spobj.maxisloc.sigslice(time_range);
                rmaxis_mean = mean(rmaxis_slice.sigunbund(spobj.RMaxisNode));
            else
                rmaxis_mean = spobj.DefaultRmajor;
            end
            spobj.bt = 4.16e-4*spobj.it.mean/rmaxis_mean;
        end
        
        function viewmflux(spobj, time_slice, rm_region)
        %% plot magnetic surface at given time
        % spobj.viewmflux(time_slice)
            if nargin == 2
                rm_region = [];
            end
            spobj.mfdatacheck;
            x = spobj.mfgridrz.sigunbund(spobj.GridRNode);
            y = spobj.mfgridrz.sigunbund(spobj.GridZNode);
            z = spobj.mfpsinorm.sigpartdata(time_slice);
            z(z>1.05) = 1.2;
            if ~isempty(rm_region)
                ind_x = x >= rm_region(1) & x <= rm_region(2);
                ind_y = y >= rm_region(3) & y <= rm_region(4);
                z(ind_x, ind_y) = nan;
            end
            time_ind = findtime(spobj.mfpsinorm.time, time_slice);
            time_slice = spobj.mfpsinorm.time(time_ind);
            
            contour(x, y, z')
            hold on
            
            if isempty(spobj.limiterrz)
                spobj.readlimiter;
            end
            plot(spobj.limiterrz(1,:), spobj.limiterrz(2,:), 'k-', 'linewidth', 3);
            
            [ind1, ind2]=find(z==min(min(z)));
            plot(x(ind1),y(ind2),'k+');
%             set(gca, 'DataAspectRatio', [1 1 1])
            
            axis equal
            caxis([0 1.05])
            title(['#' num2str(spobj.shotno) '@' num2str(time_slice,'%4.3f') 's'])
            xlabel('R [m]')
            ylabel('Z [m]')
            colorbar('EastOutside')
        end
        
        function modefittree(spobj, new_tree)
            spobj.EfitTree = new_tree;
        end
        
        function res = caldivleg(spobj, pos_tag, time_slice, disp)
            %% check arguments
            if nargin == 3
                disp = 0;
            end
            %% get Div-LP position
            pb = prbbase(spobj.shotno, pos_tag);
            port_names = pb.prb_list_portnames;
            assert(~isempty(port_names), 'Empty port name for Div-LP!')
            pb.prb_set_portname(port_names{1});
            prb_pos_rz = pb.prb_extract_distinfo('rz');
            
            prb_pos_dist = pb.prb_extract_distinfo('dist2div');
            target_r = prb_pos_rz(1, :);
            target_z = prb_pos_rz(2, :);
            % TO DO: update according limiterrz
            if strcmpi(pos_tag, 'uo')
                prb_pos_dist(end+1) = 0;
                target_r(end+1) = 1.707;
                target_z(end+1) = 1.162;
            end
            %% check equilibrium data
            if isempty(spobj.mfpsirz) || isempty(inrange(spobj.mftime([1 end]), time_slice))
                spobj.readmflux;
            end
            
            if isempty(spobj.mfbdryrz) || isempty(inrange(spobj.mfbdryrz.time([1 end]), time_slice))
                spobj.readmfbdryrz;
            end
            
            if disp
                spobj.viewmflux(time_slice)
                hold on
                plot(target_r, target_z, 'r--')
            end
            %% slice equilibrium data
            psi_rz = spobj.mfpsinorm.sigpartdata(time_slice);
            bdry_slice = spobj.mfbdryrz.sigpartdata(time_slice);
            bdry_r = bdry_slice(1, :)';
            bdry_z = bdry_slice(2, :)';
            r = spobj.mfgridrz.sigunbund('r');
            z = spobj.mfgridrz.sigunbund('z');
            %% find X point location and separatrix
            if lower(pos_tag(1)) == 'u'
                [xnull_z, z_ind] = max(bdry_z);
                xnull_z_ind = findvalue(z, xnull_z);
                valid_z_ind = xnull_z_ind:length(z);
            else
                [xnull_z, z_ind] = min(bdry_z);
                xnull_z_ind = findvalue(z, xnull_z);
                valid_z_ind = fliplr(1:xnull_z_ind);
            end
            
            xnull_r = bdry_r(z_ind);
            xnull_r_ind = findvalue(r, xnull_r);
            if lower(pos_tag(2)) == 'i'
                valid_r_ind = fliplr(1:xnull_r_ind);
            else
                valid_r_ind = xnull_r_ind:length(r);
            end
            
            sep_r = r(valid_r_ind(1));
            sep_z = z(valid_z_ind(1));
            psi_line_r = r(valid_r_ind);
            for i=2:length(valid_z_ind)
                curr_z_ind = valid_z_ind(i);
%% method 3                
%                 for j=2:length(valid_r_ind)
%                     curr_r_ind = valid_r_ind(j-1);
%                     nxt_r_ind = valid_r_ind(j);
%                     curr_psi = psi_rz(curr_r_ind, curr_z_ind)-1;
%                     nxt_psi = psi_rz(nxt_r_ind, curr_z_ind)-1;
%                     if nxt_psi*curr_psi <= 0
%                         sep_r(end+1) = r(curr_r_ind);
%                         sep_z(end+1) = z(curr_z_ind);
%                         continue
%                     end
%                 end
%% method 2                
                psi_line = psi_rz(valid_r_ind, curr_z_ind);
                tmp_r = interp1(psi_line, psi_line_r, 1, 'pchip');
                if (isnan(tmp_r) || tmp_r < min(psi_line_r) || tmp_r > max(psi_line_r)) && i > 4
                    break
                end
                sep_r(end+1) = tmp_r;
                sep_z(end+1) = z(curr_z_ind);
%% method 1
%                 tmp_ind = findvalue(psi_line, 1);
%                 tmp_r = r(valid_r_ind(tmp_ind));
% 
%                 [~,~,in_range] = inrange(psi_line_r([1 end]), tmp_r);
%                 tmp_ind = findvalue(psi_line_r, tmp_r);
%                 psi_right = abs( psi_line(valid_r_ind(tmp_ind) )-1) < 0.02;
%                 if ~in_range || ~psi_right
%                     continue
%                 end
%                 sep_r(end+1) = tmp_r;
%                 sep_z(end+1) = z(curr_z_ind);
                
            end
            
            if disp
                plot(sep_r, sep_z, 'r--');
            end
            %% find strike point
            strike_point = InterX([target_r; target_z], [sep_r; sep_z]);
            assert(~isempty(strike_point), 'Can not find the strike point!')
            
            if disp
                plot(strike_point(1), strike_point(2), 'ro')
                hold off
                p = [target_r sep_r];
                q = [target_z sep_z];
                xlim([min(p)-0.1 max(p)+0.1]);
                ylim([min(q)-0.1 max(q)+0.1]);
            end
            %% calculate divertor leg length
            sep_r = sep_r( (sep_r(1)-strike_point(1))*(sep_r-strike_point(1)) > 0);
            sep_z = sep_z( (sep_z(1)-strike_point(2))*(sep_z-strike_point(2)) > 0);
            
%             tmp_ind = findvalue(sep_r, cross_point(1))-1;
%             sep_r = sep_r(1:tmp_ind);
% 
%             tmp_ind = findvalue(sep_z, cross_point(2))-1;
%             sep_z = sep_z(1:tmp_ind);

            sep_r(end+1) = strike_point(1);
            sep_z(end+1) = strike_point(2);
            
            if length(sep_r) == length(sep_z)            
                leg_len = arclength(sep_r, sep_z);
                if disp
                    hold on
                    plot(sep_r, sep_z, 'gx-');
                    hold off
                    legend(['Leg length: ' num2str(leg_len,'%1.4f') 'm'])
                end
            else
                leg_len = nan;
            end
            %% calculate the distance from strike point to divertor corner
            prb_dist_1st_pnt = [];
            for i=1:length(prb_pos_dist)
                prb_dist_1st_pnt(i) = arclength(target_r([1 i]), target_z([1 i]));
            end
            sp_dist_1st_pnt = arclength([target_r(1) strike_point(1)], [target_z(1) strike_point(2)]);
            sp_dist_corner = pchip(prb_dist_1st_pnt, prb_pos_dist, sp_dist_1st_pnt);
            %% output results
            res.x_point = [sep_r(1) sep_z(1)];
            res.strike_point = strike_point;
            res.separtrix = [sep_r; sep_z];
            res.leg_length = leg_len;
            res.sp_distance_corner = abs(sp_dist_corner)/1000;
        end
        
    end
    
end

