function new_cell = cellremove(cell_in, cell_rm)
if ~iscell(cell_in)
    error('cell_in should be a cell!')
end
if ~iscell(cell_rm)
    cell_rm = {cell_rm};
end

inds = [];
for i=1:length(cell_rm)
    [res, ind] = haselement(cell_in, cell_rm{i});
    if res
        inds(end+1) = ind;
    end
end

new_cell = cell_in;
new_cell(inds) = [];