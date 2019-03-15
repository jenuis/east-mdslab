function setfigpostion(position)
if nargin == 0
    fig_size = [0 0 1 1];
else
    if ischar(position)
        switch position
            case 'left'
                fig_size = [.0 .0 .5 1];
            case 'right'
                fig_size = [.5 .0 .5 1];
            case 'full'
                fig_size = [0 0 1 1];
        end
    elseif isnumeric(position) && length(position)==4
        fig_size = position;
    else
        error('wrong input arguments!')
    end
end
set(gcf,'unit','normalized','outerposition', fig_size);