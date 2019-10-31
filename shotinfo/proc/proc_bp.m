function bp = proc_bp(shotno, time_range, efit_tree)
if nargin < 2
    time_range = [];
end
if nargin < 3
    efit_tree = 'efit_east';
end

efit_info = efit_map(shotno,[],1, time_range, 1, efit_tree);

bp.time = efit_info.time;
bp.data = efit_info.lcfs_mid_bp;

bp.mean = mean(bp.data, 'omitnan');

bp = signal_check(bp);
