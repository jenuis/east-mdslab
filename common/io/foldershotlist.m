function [shotlist, filelist] = foldershotlist(Dirs, FilterStr, shotno_ind)
if nargin == 2
    shotno_ind = 5:9;
end
if ischar(Dirs)
    [shotlist, filelist] = listone(Dirs, FilterStr, shotno_ind);
elseif iscellstr(Dirs)
    [shotlist, filelist] = listmany(Dirs, FilterStr, shotno_ind);
else
    error('Bad input type!')
end
if iscell(shotlist) && length(shotlist) == 1
    shotlist = shotlist{1};
    filelist = filelist{1};
end


% if ~no_sort
%     shotlist = sort(shotlist);
% end


function [shotlist, filelist] = listmany(Dirs, FilterStr, shotno_ind)
if ~iscellstr(Dirs)
    error('Only path accepted!')
end
shotlist = {};
filelist = {};
for i=1:length(Dirs)
    [shotlist{i}, filelist{i}] = listone(Dirs{i}, FilterStr, shotno_ind);
end

function [shotlist, filelist] = listone(Dirs, FilterStr, shotno_ind)
if ~ischar(Dirs)
    error('Only path accepted!')
end
dir_list = rdir(fullfile(Dirs, FilterStr));
shotlist = [];
filelist = {};
for i=1:length(dir_list)
    d = dir_list(i).name;
    filelist{end+1} = d;
    [~, file_name] = fileparts(d);
    shotlist(i) = str2double(file_name(shotno_ind));
end
bad_ind = isnan(shotlist);
shotlist(bad_ind) = [];
filelist(bad_ind) = [];