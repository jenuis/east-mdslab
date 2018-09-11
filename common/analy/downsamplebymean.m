function array_out = downsamplebymean(array_in, avg_len)
%% average data along row by step of avg_len
% Xiang Liu@ ASIPP
% Modified@2017-3-16
if avg_len == 1
    array_out = array_in;
    return
end
shape = size(array_in);
if shape(2) < shape(1)
    array_in = array_in';
    shape = size(array_in);
end
new_len = floor(shape(2)/avg_len);
array_out = zeros(shape(1),new_len);
for i=1:shape(1)
    array_out(i,:) = mean(reshape(array_in(i,1:new_len*avg_len),avg_len,new_len));
end
end