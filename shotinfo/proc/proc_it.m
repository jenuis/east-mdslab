function it = proc_it(shotno)
sp = shotpara(shotno);
sp.readit
it.name = sp.it.nodename;
it.mean = sp.it.mean;
if isnan(it.mean)
    it.status = 0;
else
    it.status = 1;
end

% if shotno > 65321
%     it = mdsreadsignal(shotno, 'east', '\focs4');
%     it.name = 'focs4';
% else
%     it = mdsreadsignal(shotno, 'east', '\focs_it');
%     it.name = 'focs_it';
% end
% it = check_it(it);
% if it.status
%     return
% end
% 
% it = mdsreadsignal(shotno, 'eng_tree', '\it');
% it.name = 'it';
% it = check_it(it, 1);
% if it.status
%     return
% end
% 
% it = mdsreadsignal(shotno, 'pcs_east', '\sysdrit');
% it.name = 'sysdrit';
% it = check_it(it);
% if ~it.status
%     it = rmfield(it, 'name');
% end



% function it = check_it(it, only_tail)
% if nargin == 1
%     only_tail = 0;
% end
% it = signalcheck(it);
% if ~it.status
%     return
% end
% if only_tail
%     startind = floor(length(it.data)*0.95);
%     tmp = it.data(startind:end);
% else
%     tmp = it.data;
% end
% value = mean(tmp);
% if abs(abs(value)-10500) > 3500
%     it.status = 0;
%     return
% end
% it.mean = value;