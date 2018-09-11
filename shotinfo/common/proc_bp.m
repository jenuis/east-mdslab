function bp = proc_bp(shotno, time_range)
if nargin == 1
    time_range = [];
end

efit_info = efit_map(shotno,[],1, time_range, 1);

bp.time = efit_info.time;
bp.data = efit_info.lcfs_mid_bp;

bp = signal_check(bp);
