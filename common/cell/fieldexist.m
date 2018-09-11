function [bool, var] = fieldexist(var, cell_array_str)
bool = 1;
if ischar(cell_array_str)
    cell_array_str = {cell_array_str};
end
for i = 1:length(cell_array_str)
    if ~isfield(var, cell_array_str{i})
        bool = 0;
        return
    end
    var = var.(cell_array_str{i});
end