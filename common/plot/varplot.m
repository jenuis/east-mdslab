function varplot(x, y, varargin)
    varargin = revvarargin(varargin);
    Args = struct(...
        'SkipPlot',0,...
        'HoldOn',0,...
        'ErrData',[],...
        'XLabel', '',...
        'YLabel', '',...
        'Title', '',...
        'XLim', [],...
        'YLim', [],...
        'LineSpec', '',...
        'Legend', '');
            
    Args = parseArgs(varargin, Args, {'HoldOn', 'SkipPlot'});
    
    if ~Args.SkipPlot
        z = Args.ErrData;

        if isempty(y)
            warning('y axis data is empty!')
            return
        end

        if isempty(x)
            x = 1:length(y);
        end

        if isempty(z)
            plot(x, y, Args.LineSpec);
        else
            errorbar(x, y, z, Args.LineSpec);
        end
    end
    
    if ~isempty(Args.XLabel)
        xlabel(Args.XLabel)
    end
    if ~isempty(Args.YLabel)
        ylabel(Args.YLabel)
    end
    
    if ~isempty(Args.Title)
        title(Args.Title)
    end
    
    if ~isempty(Args.XLim)
        xlim(Args.XLim)
    end
    if ~isempty(Args.YLim)
        ylim(Args.YLim)
    end
    
    if ~isempty(Args.Legend)
        legend(Args.Legend)
    end
    
    if Args.HoldOn
        hold on
    end
end