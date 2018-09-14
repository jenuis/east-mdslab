function h = contourfjet(x, y, z)
    if nargin == 1
        h = contourf(x, 50,'linestyle','none');
    elseif nargin == 3
        h = contourf(x, y, z, 50,'linestyle','none');
    else
        error('invalid argument number!')
    end
    shading flat
    colormap(jet)