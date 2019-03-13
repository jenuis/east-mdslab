function res = efit_map(shotno, location_rz, map2out ,time_range, no_mapping)
%% This function is used to caculate the psi-projected R @out mid-plane for divertor probes of a given shot.
% Also given is Rmid_probe,Bp_probe,Bp_mid 
% first created by L.Wang
% last Modified by Xiang LIU @2018-9-12
%% constants
EfitTree = 'efit_east';
%% read efit data
if nargin == 3
    efit = efit_read(shotno);
    time_range = efit.time([1 end]);
else
    atime = efit_read(shotno, [], EfitTree, {});
    if isempty(atime)
        res = [];
        return
    end
    dt = median(atime.time);
    if length(time_range) == 1 || length(time_range) == 2 && abs(diff(time_range)) < dt
        time_range_new = time_range(1) + [0 dt];
    else
        time_range_new = time_range;
    end
    efit = efit_read(shotno, time_range_new, EfitTree);
end
%% check arguments
if nargin < 5
    no_mapping = 0;
end
if isempty(time_range)
    time_range = efit.time([1 end]);
end
%% extract location data
if ~no_mapping
    loc_r = location_rz(1,:)';
    loc_z = location_rz(2,:)';
end
%% cal data
time_ind = timerngind(efit.time, time_range);
time_ind_len = time_ind(end)-time_ind(1)+1;

time        = [];
rmaxis      = [];
zmaxis      = [];
a           = [];
lcfs_mid_r  = [];
lcfs_mid_z  = [];
lcfs_mid_bp = [];
map_mid_r   = [];
map_bp      = [];
map_mid_bp  = [];
map_rel_r   = [];

for i=1:time_ind_len
    %% get current time index
    curr_time_ind = i - 1 + time_ind(1);
    %% extract psi data @ current time
    psi_rz = efit.psirz(:, :, curr_time_ind)';
    bdry_r = efit.bdry(1, 1:efit.nbdry(curr_time_ind), curr_time_ind)'; 
    bdry_z = efit.bdry(2, 1:efit.nbdry(curr_time_ind), curr_time_ind)';
    if ~no_mapping
        map_psi = interp2(efit.r, efit.z, psi_rz, loc_r, loc_z, 'spline');  %psi value at  probe locations
    end
    %% calculate Poloidal field
    [psi_grad_r, psi_grad_z] = gradient(psi_rz, efit.r, efit.z);
    RR = ones(size(efit.z))*efit.r';
    Br = -psi_grad_z./RR;
    Bz = psi_grad_r./RR;
    Bp = sqrt(Br.^2+Bz.^2);  
    %% get magnetic axis postion value
    r_maxis = efit.rmaxis(curr_time_ind);
    z_maxis = efit.zmaxis(curr_time_ind);
    %% check rmaxis
    if r_maxis >= efit.r(end)
        continue
%         error(['Invalid efit value of rmaxis @' num2str(efit.time(curr_time_ind))])
    end
    %% generate midplane line (r, z) value
    if map2out
        mid_line_r = r_maxis:0.001:efit.r(end);
    else
        mid_line_r = efit.r(1):0.001:r_maxis;
    end
    mid_line_z = z_maxis*ones(size(mid_line_r));
    %% get midplane line psi value
    mid_line_psi = interp2(efit.r, efit.z, psi_rz, mid_line_r, mid_line_z);
    %% map probe r to midplane
    if ~no_mapping
        tmp_map_mid_r = interp1(mid_line_psi, mid_line_r, map_psi, 'PCHIP');
    end
    %% get lcfs r @ midplane 
    tmp_lcfs_mid_r = get_midplane_r(bdry_r, bdry_z, z_maxis, map2out); % R of LCFS @out mid-plane
    if isnan(tmp_lcfs_mid_r)
        continue
    end
    tmp_lcfs_mid_z = z_maxis; % Z of LCFS @out mid-plane
    
    tmp_a = get_midplane_r(bdry_r, bdry_z, z_maxis, ~map2out);
    tmp_a = abs(tmp_a - tmp_lcfs_mid_r)/2;
    %% obtain Bp_probe and Bp_mid  
    if ~no_mapping
        tmp_map_bp = interp2(efit.r, efit.z, Bp, loc_r, loc_z, 'spline');
        tmp_map_mid_bp = interp2(efit.r, efit.z, Bp, tmp_map_mid_r, z_maxis,'spline');
    end
    %% obtain Bp midplane out @ lcfs
    tmp_lcfs_mid_bp = interp2(efit.r, efit.z, Bp, tmp_lcfs_mid_r, z_maxis,'spline'); 
    %% cal probe R-Rsep
    if ~no_mapping
        tmp_map_rel_r = tmp_map_mid_r - tmp_lcfs_mid_r;
    end
    %% gather data cener
    time(end+1) = efit.time(curr_time_ind);
    rmaxis(end+1) = r_maxis;
    zmaxis(end+1) = z_maxis;
    a(end+1) = tmp_a;
    lcfs_mid_r(end+1) = tmp_lcfs_mid_r;
    lcfs_mid_z(end+1) = tmp_lcfs_mid_z;
    lcfs_mid_bp(end+1) = tmp_lcfs_mid_bp;
    if ~no_mapping
        map_mid_r(:,end+1) = tmp_map_mid_r;
        map_bp(:,end+1) = tmp_map_bp;
        map_mid_bp(:,end+1) = tmp_map_mid_bp;
        map_rel_r(:, end+1) = tmp_map_rel_r;
    end
end
%% generate outputs
if isempty(time)
    res = [];
    return
end
res.time = time;
res.maxis_r = rmaxis;
res.maxis_z = zmaxis;
res.a = a;

res.lcfs_mid_r = lcfs_mid_r;
res.lcfs_mid_z = lcfs_mid_z;
res.lcfs_mid_bp = lcfs_mid_bp;

if ~no_mapping
    res.map_bp = map_bp;
    res.map_mid_bp = map_mid_bp;
    res.map_mid_r = map_mid_r;
    res.map_rel_r = map_rel_r*1e3; %unit [mm]
    
    res.fx = res.map_mid_bp.*res.map_mid_r./res.map_bp./(loc_r*ones(1,length(res.time)));
    
    res.map2out = map2out;
end

function lcfs_mid_r = get_midplane_r(bdry_r, bdry_z, z_maxis, omp)
    lcfs_mid_r = nan;

    [~, bdry_z_max_ind] = max(bdry_z);
    [~, bdry_z_min_ind] = min(bdry_z);
    if omp
        lcfs_extract_ind = bdry_z_max_ind:bdry_z_min_ind;
    else
        lcfs_extract_ind = [bdry_z_min_ind:length(bdry_z) 1:bdry_z_max_ind];
    end
    lcfs_half_r = bdry_r(lcfs_extract_ind);           
    lcfs_half_z = bdry_z(lcfs_extract_ind);
    if isempty(lcfs_half_z) || isempty(z_maxis)
        return
    end
    lcfs_mid_r_ind = findvalue(lcfs_half_z, z_maxis);
    lcfs_mid_r = lcfs_half_r(lcfs_mid_r_ind); % R of LCFS at mid-plane
    