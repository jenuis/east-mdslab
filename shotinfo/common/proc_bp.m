function output = proc_bp(shotno, time_range)
output = [];
% return
error('Need to improve by efit_map!')
map2out = 1;
EfitTree = 'efit_east';
%% read efit data
if nargin == 1
    efit = mdsreadefit(shotno);
    time_range = efit.time([1 end]);
else 
    atime = mdsreadefit(shotno, [], EfitTree, {});
    dt = median(atime.time);
    if length(time_range) == 1 || length(time_range) == 2 && abs(diff(time_range)) < dt
        time_range_new = time_range(1) + [0 dt];
    else
        time_range_new = time_range;
    end
    efit = mdsreadefit(shotno, time_range_new, EfitTree);
end
%% cal data
time_ind = timerngind(efit.time, time_range);
time_ind_len = time_ind(end)-time_ind(1)+1;
lcfs_mid_r  = zeros(1, time_ind_len);
lcfs_mid_bp = zeros(1, time_ind_len);
for i=1:time_ind_len
    %% get current time index
    curr_time_ind = i - 1 + time_ind(1);
    %% extract psi data @ current time
    psi_rz = efit.psirz(:, :, curr_time_ind)';
    bdry_r = efit.bdry(1, 1:efit.nbdry(curr_time_ind), curr_time_ind)'; 
    bdry_z = efit.bdry(2, 1:efit.nbdry(curr_time_ind), curr_time_ind)'; 
    %% calculate Poloidal field
    [psi_grad_r, psi_grad_z] = gradient(psi_rz, efit.r, efit.z);
    RR = ones(size(efit.z))*efit.r';
    Br = -psi_grad_z./RR;
    Bz = psi_grad_r./RR;
    Bp = sqrt(Br.^2+Bz.^2);  
    %% get magnetic axis postion value
    r_maxis = efit.rmaxis(curr_time_ind);
    z_maxis = efit.zmaxis(curr_time_ind);
    if r_maxis >= efit.r(end)
        error(['Invalid efit value of rmaxis @' num2str(efit.time(curr_time_ind))])
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
    %% get lcfs r @ midplane 
    [~, bdry_z_max_ind] = max(bdry_z);
    [~, bdry_z_min_ind] = min(bdry_z);
    if map2out
        lcfs_extract_ind = bdry_z_max_ind:bdry_z_min_ind;
    else
        lcfs_extract_ind = [bdry_z_min_ind:length(bdry_z) 1:bdry_z_max_ind];
    end
    lcfs_half_r = bdry_r(lcfs_extract_ind);           
    lcfs_half_z = bdry_z(lcfs_extract_ind);
    lcfs_mid_r_ind = findvalue(lcfs_half_z, z_maxis);
    lcfs_mid_r(i) = lcfs_half_r(lcfs_mid_r_ind); % R of LCFS @out mid-plane
    %% obtain Bp midplane out @ lcfs
    lcfs_mid_bp(i) = interp2(efit.r, efit.z, Bp, lcfs_mid_r(i), z_maxis,'spline'); 
end
%% generate outputs
output.time = efit.time(time_ind(1):time_ind(end));
output.data = lcfs_mid_bp;
output.mean = mean(lcfs_mid_bp);
output.std = std(lcfs_mid_bp);

output.maxis_r = efit.rmaxis(time_ind(1):time_ind(end));
output.maxis_z = efit.zmaxis(time_ind(1):time_ind(end));
output.R = lcfs_mid_r;
output.map2out = map2out;
