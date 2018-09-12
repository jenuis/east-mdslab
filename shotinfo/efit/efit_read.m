function data = efit_read(shotno, time_range, tree_name, node_list)
%% read efit data from mds server
% Xiang Liu@ASIPP
% Modified @ 2018-9-12
%% constants
NODE_LIST = {'\rmaxis', '\zmaxis', '\psirz', '\bdry', '\nbdry', '\r', '\z'};
%% Check arguments
default_tree = getdefaulttree;
if nargin == 3
    if iscell(tree_name)
        node_list = tree_name;
        tree_name = default_tree;
    else
        node_list = [];
    end
elseif nargin == 2
    tree_name = default_tree;
    node_list = [];
elseif nargin == 1
    tree_name = default_tree;
    node_list = [];
    time_range = [];
end
if ~ischar(tree_name)
    error('mdsreadefit: invalid tree name!');
end
if length(time_range) == 1
    time_range(2) = time_range;
end
if isempty(node_list)
    node_list = NODE_LIST;
end
%% read first node
sig = signal(shotno, tree_name, node_list{1}, 'TR',time_range, 'rn');
if ~signal_check(sig)
    error('mdsreadefit: no data for this shot!\n');
end
data.time = sig.time;
data.(sig.nodename) = sig.data;
%% read other nodes
for i = 2:length(node_list)
    sig.nodename = node_list{i};
    if hastimedim(sig.nodename)
        sig.sigread;
    else
        sig_time = sig.time;
        sig.time = [];
        sig.sigread;
        sig.time = sig_time;
    end
    data.(sig.nodename) = sig.data;
end


function default_tree = getdefaulttree
default_tree = 'efit_east';
% function default_tree = getdefaulttree(shotno)
% efitrt_east only 32*32 grids
% efit_east has 128*128 grids
% drsep seems has unit problems for 2012 campain
% if shotno <= 44326
%     default_tree = 'efitrt_east';
% else
%     default_tree = 'efit_east';
% end



function bool = hastimedim(node_name)
switch node_name
    case {'\psirz', '\bdry', '\nbdry',  '\rmaxis', '\zmaxis'}
        bool = 1;
    case {'\r', '\z',}
        bool = 0;
    otherwise
         error('mdsreadefit: unsupport node name!');   
end

