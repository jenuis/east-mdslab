function shot_cmp(varargin)
shotlist = [varargin{:}];
if length(shotlist) > 3 || length(shotlist) < 1
    error('varargin should be in the range of [1 3]!');
end

TreeList = {'pcs_east', 'pcs_east', 'efit_east', 'east_1', 'east_1'};
NodeList = {'pcrl01',   'dfsdev',   'wmhd',      'plhi1',  'plhi2'};

ColorList = {'k', 'r', 'b'};
TotSub = length(NodeList);


for i=1:TotSub
    subplot(TotSub, 1, i)
    legend_str ={};
    for j = 1:length(shotlist)
        sig = signal(shotlist(j), TreeList{i}, NodeList{i}, 'rn');
        sig.sigplot('ls', ColorList{j}, 'holdon',...
            'ylim', [min(sig.data) max(sig.data*1.2)],...
            'xlim', [0 sig.time(end)])
        legend_str{end+1} = num2str(shotlist(j));
    end
    ylabel(NodeList{i});
    legend(legend_str);
end

samexaxis('join', 'YTAC','yld',1);
xlabel('time');
end