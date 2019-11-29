function line_objs = getlines(axe_obj, line_no, line_type)
if nargin == 0
    axe_obj = gca;
end
if nargin < 3
    line_type = 'Line';
end
if ischar(line_type)
    line_type = {line_type};
end
line_type = lower(line_type);
line_objs = findobj(axe_obj);
line_objs = flip(line_objs);
bad_ind = [];
for i=1:length(line_objs)
    if ~haselement(line_type, line_objs(i).Type)
        bad_ind(end+1) = i;
    end
end
line_objs(bad_ind) = [];
if isempty(line_objs)
    return
end
if nargin < 2
    return
end
if ~isempty(line_no) && isnumeric(line_no) && line_no > 0
    line_objs = line_objs(line_no);
end
