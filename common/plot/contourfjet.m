function h = contourfjet(x, y, z, N)
if nargin < 4
    N = 50;
end
if nargin == 1
    [~, h] = contourf(x, N,'linestyle','none');
else
    [~, h] = contourf(x, y, z, N,'linestyle','none');
end
shading flat
colormap(jet)
