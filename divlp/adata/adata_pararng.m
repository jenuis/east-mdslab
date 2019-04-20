function para_range = adata_pararng(data, varargin)
%% arguments check
Args = struct('RmRatio',0.02,...
    'PlotVarName',[],...
    'PlotVarNameUnit',[],...
    'PlotShowRng', 0,...
    'PlotShowStd', 1,...
    'UseRobust', 0);
Args = parseArgs(varargin, Args);
rm_ratio = Args.RmRatio;
XName = Args.PlotVarName;
XUnit = Args.PlotVarNameUnit;
show_rng = Args.PlotShowRng;
show_std = Args.PlotShowStd;
use_robust = Args.UseRobust;
if isempty(XName)
    PlotFig = 0;
else
    PlotFig = 1;
end
%% process
adata_info
var_no = size(data,1);
para_range = {};
var_min = [];
var_max = [];
nui = [];
sigma = [];
skew = [];
kurt = [];
stdis   = [];
for i=1:var_no
    tmp=[data{i,:}];
    if isempty(tmp)
        continue
    end
    tmp(isnan(tmp)) = [];
    
    var_min(i) = min(tmp);
    var_max(i) = max(tmp);
        
    [N,X] = hist(tmp,100);
    Flag = 2;
    total_len = sum(N);
    for j=1:length(X)
        if ~Flag
            break
        elseif Flag == 2
            val = sum(N(1:j))/total_len;
            if val <= rm_ratio
                var_min(i) = X(j);
            else
                Flag = Flag - 1;
            end
        elseif Flag == 1
            val = sum(N(j:end))/total_len;
            if val > rm_ratio
                var_max(i) = X(j);
            else
                Flag = Flag - 1;
            end
        end
    end
    
    tmp(tmp < var_min(i) | tmp > var_max(i)) = [];
    
    if use_robust
        nui(i) = median(tmp,'omitnan');
        sigma(i) = mad(tmp,'omitnan');
        mean_txt = 'median';std_txt = 'MAD';
    else
        nui(i) = mean(tmp,'omitnan');
        sigma(i) = std(tmp,'omitnan');
        mean_txt = 'mean';std_txt = 'std';
    end
    
    skew(i) = skewness(tmp);
    kurt(i) = kurtosis(tmp);
    stdis(i) = sigma(i)/nui(i);
    tmp_str = [DataType{i} ': '...
        'Range[ ' num2str(var_min(i),'%0.2f') '~'...
        num2str(var_max(i),'%0.2f') ']; Var['...
        num2str(stdis(i)*100,'%0.1f') '%]; Median[' ...
        num2str(nui(i), '%.2f') ']; Skew['...
        num2str(skew(i), '%.2f') ']; Kurt['...
        num2str(kurt(i), '%.2f') ']'
        ];
    para_range{end+1} = tmp_str;
end
%% plot
if ~PlotFig
    return
end

xname_len = length(XName);
row_no = floor(sqrt(xname_len));
col_no = ceil(xname_len/row_no);
fig
setfigpostion

for i=1:xname_len
    var_ind = adata_getrowno(XName{i});
    subplot(row_no, col_no, i)
    if var_ind > var_no
        continue
    end
    tmp = [data{var_ind,:}];
    if isempty(tmp)
        continue
    end
    tmp(tmp < var_min(var_ind) | tmp > var_max(var_ind)) = [];
    hist(tmp,100);
    x_lim = [var_min(var_ind) var_max(var_ind)];
    if show_rng
        hold on
        errorbar(x_lim, [2.5 2.5], [5 5], 'rp:')
    end
    x_lim = xlim;
    y_lim = ylim;
    if show_std
        legend([DataType{var_ind} ': ' num2str(stdis(var_ind)*100, '%2.2f') '%'])
    end
    if xname_len <= 12
        ylabel('Frequency');
        x_label = DataType{var_ind};
        if ~isempty(XUnit) && ~isempty(XUnit{i})
            x_label = [x_label ' ' XUnit{i}];
        end
        xlabel(x_label);
%         legend off
%         if show_std
            txt = sprintf('%s: %.3f\n%s: %.3f\nskewness: %.3f\nkurtosis: %.3f',...
                mean_txt,nui(var_ind), std_txt,sigma(var_ind),skew(var_ind),kurt(var_ind));
            textbp(txt,'color','r','fontsize',12);
%         end
        xlim(x_lim)
    end
end