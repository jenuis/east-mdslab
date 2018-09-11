function path = chkdir(varargin)
path = '';
for i=1:length(varargin)
    path = fullfile(path, varargin{i});
end
if ~exist(path, 'dir')
    mkdir(path)
    disp(['mkdir: ' path]);
end