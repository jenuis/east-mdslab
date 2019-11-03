function var = struct2vararg(s)
if ~isstruct(s)
    error('input should be a struct!')
end
fnames = fieldnames(s);
var = {};
for i=1:length(fnames)
    var{end+1} = fnames{i};
    var{end+1} = s.(var{end});
end