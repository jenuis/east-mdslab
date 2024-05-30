function eastmds_addpath(module_name)
%% get current dir
curr_dir = fileparts(mfilename('fullpath'));
%% add necessary path
addpath(genpath(fullfile(curr_dir, 'mdslib')));
assert(exist('matutil_addpath.m','file') == 2, ...
    '"matlab-utils" not in the path! Use "git clone https://github.com/jenuis/matlab-utils.git" to download the repo and add the root of the repo into "MATLABPATH".')
matutil_addpath();
if nargin < 1
    return
end
%% check module_name
subdirs = dir(curr_dir);
assert(any(strcmpi({subdirs(:).name}, module_name)), ['"east-mdslab.' module_name '" not exist!'])
%% add module
addpath(genpath(fullfile(curr_dir, module_name)));