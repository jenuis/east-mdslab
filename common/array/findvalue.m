%% Find indices of the values in array. 
% if values_to_find is a 1-D array and ind_no_to_find >1, 
% then indices is a 2-D array.
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
% Last modified by Xiang Liu @ 2017-4-10
function indices = findvalue(array, values_to_find, ind_no_to_find)
%% check arguments
if nargin == 2
    ind_no_to_find = 1;
end
%% allocate memory for outputs
indices = zeros(length(values_to_find), ind_no_to_find);
%% find index
    for i = 1:length(values_to_find)
        temp = abs(array-values_to_find(i));
        % has target value in array, then return exact ind of the value
        % since indices are initialized, then if ind_no_to_find >1,
        % will return same ind in indices!
        if ~isempty(find(temp==0, 1))
            % if ind_no_to_find >1, return same ind for all i row.
            indices(i,:) = find(temp==0, ind_no_to_find);
        % find closest value instead
        else    
            temp(temp==0) = max(temp);
            result = find(temp==min(temp));
            indices(i,1) = result(1);
            if ind_no_to_find > 1
                for j = 2:ind_no_to_find
                    temp = temp-temp(indices(i, j-1));
                    temp(temp==0) = max(temp);
                    result = find(temp==min(temp));
                    indices(i, j) = result(1);
                end
            end
        end
    end
end