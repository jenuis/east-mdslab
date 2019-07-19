classdef shotpara < mdsbase
    %SHOTPARA collects plasma parameter for one shot
    %Derived from mdsbase
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
    
    % Xiang Liu@ASIPP 2017-9-12
    % jent.le@hotmail.com
    properties
    %% public properties
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
    end
    properties(Access = protected)
    %% protected properties 
        efit_status = nan;
    end
    properties(Constant, Access = protected)
    %% protected constant properties
        EfitTree = 'efit_east';
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
        DefaultRmajor =  1.85;
        DefaultRminor = 0.45;
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
        function time_range = mftimerngcheck(spobj, time_range, keep_slice)
            if nargin == 2
                keep_slice = 0;
            end
            if isempty(spobj.mftime)
                spobj.readmftime;
            end
            if isempty(time_range)
                time_range = spobj.mftime([1 end]);
            % ensure psirz has the third dim
            elseif length(time_range) == 1 && ~keep_slice
                time_range = time_range + [0 0.1];
            end
        end
        function check_efit_status(spobj)
            m = mds;
            [~, spobj.efit_status] = m.mdsread(spobj.shotno, spobj.EfitTree, ['\' spobj.EfitTimeNode '[0]']);
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
        %% read Bt0
        % spobj.readit
            if ~isempty(spobj.it)
                return
            end
            sig_it = signal(spobj.shotno);
            % read technical diagnosic
            sig_it.treename = 'east';
            if spobj.shotno > 65321
                sig_it.nodename = 'focs4';
            else
                sig_it.nodename = 'focs_it';
            end
            try
                sig_it.sigreaddata;
                spobj.extract_it(sig_it);
            catch
                % read eng_tree it
                try
                    sig_it.treename = 'eng_tree';
                    sig_it.nodename = 'it';
                    sig_it.sigreaddata;
                    spobj.extract_it(sig_it, 1);
                catch
                    % read pcs_east sysdrit
                    sig_it.treename = 'pcs_east';
                    sig_it.nodename = 'sysdrit';
                    sig_it.sigreaddata;
                    spobj.extract_it(sig_it);
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
        function norm_psi = calnormpsi(spobj, r, z, time_range)
        %% calculate normlized psi by (r,z) location
        % orm_psi = spobj.calnormpsi(r, z)
        % orm_psi = spobj.calnormpsi(r, z, time_range)
            spobj.mfdatacheck;
            if nargin == 3
                time_range = [];
            end
            time_range = spobj.mftimerngcheck(time_range);
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
    end
    
end

