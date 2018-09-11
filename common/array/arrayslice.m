function A_out = arrayslice(A_in, dimension, index_range)
%https://stackoverflow.com/questions/27969296/dynamic-slicing-of-matlab-array
subses = repmat({':'}, [1 ndims(A_in)]);
subses{dimension} = index_range;
A_out = A_in(subses{:});