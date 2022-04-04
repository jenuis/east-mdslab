%% Method for downsampling data by averaging
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
%% average data along row by step of avg_len
% Xiang Liu@ ASIPP
% Modified@2017-3-16
function array_out = downsamplebymean(array_in, avg_len, avg_method)
if avg_len == 1
    array_out = array_in;
    return
end
if nargin < 3
    avg_method = 'mean';
end
[res, ind] = haselement({'mean', 'median'}, avg_method);
if ~res
    error('Not recognized avg method!')
end
if ind == 1
    avg_method = @mean;
else
    avg_method = @median;
end
shape = size(array_in);
if shape(2) < shape(1)
    array_in = array_in';
    shape = size(array_in);
end
new_len = floor(shape(2)/avg_len);
array_out = zeros(shape(1),new_len);
for i=1:shape(1)
    array_out(i,:) = avg_method(reshape(array_in(i,1:new_len*avg_len),avg_len,new_len));
end
end