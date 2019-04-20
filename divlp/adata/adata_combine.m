function [data, data_ind] = adata_combine(varargin)
if length(varargin) == 1 && min(size(varargin{1})) == 1
    varargin = varargin{1};
end
data = {};
data_ind = {};
offset = 0;
for i=1:length(varargin)
    tmp_data = varargin{i};
    len = size(tmp_data,2);
    data(:,end+1:end+len)=tmp_data;
    data_ind{end+1} = (1:len) + offset;
    offset = offset + len;
end