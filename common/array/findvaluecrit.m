function indices = findvaluecrit(array, values_to_find, max_diff)
% Last modified by Xiang Liu @ 2017-4-10
% Find indices of the values in array. if values_to_find is a 1-D array
% and ind_no_to_find >1, then indices is a 2-D array.
%% allocate memory for outputs
indices = zeros(length(values_to_find), 1);
%% find index
    for i = 1:length(values_to_find)
        temp = abs(array-values_to_find(i));
        % has target value in array, then return exact ind of the value
        % since indices are initialized, then if ind_no_to_find >1,
        % will return same ind in indices!
        if ~isempty(find(temp==0, 1))
            % if ind_no_to_find >1, return same ind for all i row.
            indices(i,:) = find(temp==0, 1);
        % find closest value instead
        else    
            temp(temp==0) = max(temp);
            result = find(temp==min(temp));
            indices(i,1) = nan;
            for j=1:length(result)
                if abs(array(result(j))-values_to_find(i)) <= max_diff
                    indices(i,1) = result(j);
                    break
                end
            end
        end
    end
end