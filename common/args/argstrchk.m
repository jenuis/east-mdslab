function [str, cell_str] = argstrchk(cell_str, str)
%% check arguments
if ~ischar(str)
    error('argument str is not a string!')
end
if ~iscellstr(cell_str)
    error('argument cell_str is not a cellstr')
end
%% main
str = lower(strrmsymbol(str));
for i=1:length(cell_str)
    cell_str{i} = lower(strrmsymbol(cell_str{i}));
end
[found, ind] = haselement(cell_str, str);
if ~found
    error(['"' str '" is not in {"' strjoin(cell_str, '", "') '"}!'])
end
str = cell_str{ind};