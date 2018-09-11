function vararg = revvarargin(vararg, varargin)
while(1)
    if length(vararg) == 1 && iscell(vararg{1})
        vararg = vararg{:};
    else
        break
    end
end
if nargin > 1
    varargin(end+(1:length(vararg))) = vararg;
    vararg = varargin;
end