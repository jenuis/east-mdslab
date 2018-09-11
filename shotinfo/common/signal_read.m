function signal_out = signal_read(shotno, tree_name, node_names, time_range)
%% last modified: 2018-9-11 by xiangl
%% check arguments
if nargin == 3
    time_range = [];
end
%% return if node_names is a string
if ischar(node_names)
    sig = signal(shotno, tree_name, node_names);
    try
        sig.sigread(time_range);
    catch e
        disp(e)
    end
    signal_out.time = sig.time;
    signal_out.data = sig.data;
    signal_out.status = signal_check(sig);
    return
end
%% node_names is a cell
signal_out = struct();
for i=1:length(node_names)
    node_name = node_names{i};
    sig = signal_read(shotno, tree_name, node_name, time_range);
    if sig.status
        signal_out.(node_name) = sig;
    end
end