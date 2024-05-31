function addpath_eastmds(sub_module)
%% get current dir
curr_dir = fileparts(mfilename('fullpath'));
%% add necessary path
addpathchk('east-mdslab', 'mdslib', curr_dir)
assert(exist('addpath_matutil.m','file') == 2, ...
    '"matlab-utils" not in the path! Use "git clone https://github.com/jenuis/matlab-utils.git" to download the repo and add the root of the repo into "MATLABPATH".')
addpath_matutil();
if nargin < 1
    return
end
%% add sub module
addpathchk('east-mdslab', sub_module, curr_dir);
