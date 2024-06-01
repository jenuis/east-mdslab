function addpath_mdslab(sub_module, operation)
%% check argument
if nargin < 2
    operation = 'add';
end
if nargin < 1
    sub_module = '';
end
%% get current dir
curr_dir = fileparts(mfilename('fullpath'));
%% add necessary path
repopathctrl(curr_dir, 'mdslib', operation);
assert(exist('addpath_matutil.m','file') == 2, ...
    '"matlab-utils" not in the path! Use "git clone https://github.com/jenuis/matlab-utils.git" to download the repo and add the root of the repo into "MATLABPATH".')
addpath_matutil('', operation);
if isempty(sub_module)
    return
end
%% add sub module
repopathctrl(curr_dir, sub_module, operation);
