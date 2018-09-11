function signal_parent = signalread(shotno, tree_name, node_names, time_range)
%% output initialization and check arguments
signal_parent = struct();
if ischar(node_names)
    node_names = {node_names};
end
%% read and check data
for i=1:length(node_names)
    node_name = node_names{i};
    if node_name(1) == '\'
        node_name = node_name(2:end);
    end
    if nargin == 3
        signal = signalcheck( mdsreadsignal(shotno, tree_name, ['\' node_name]) );

    else
        signal = signalcheck( mdsreadsignal(shotno, tree_name, ['\' node_name], time_range) );
    end
    if signal.status
        signal_parent.(node_name) = signal;
    end
end