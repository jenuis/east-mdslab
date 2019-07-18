function str = argstr_extract(cell_str, str)
str = lower(strrmsymbol(str));
for i=1:length(cell_str)
    cell_str{i} = lower(strrmsymbol(cell_str{i}));
end
[found, ind] = haselement(cell_str, str);
if ~found
    error(['"' str '" is not a valid candidate input!'])
end
str = cell_str{ind};