function [te, p, ind_axis] = proc_tecore_hrs(shotno, time_range)
sp = shotpara(shotno);
sp.readpulse;
if nargin < 2
    time_range = sp.pulseflat;
end
sp.readmaxis;
te.time = [];
te.data = [];
te.status = 0;

p = profile(shotno, 'hrs');
try
    p.loadbycal(time_range, [-0.13 0.2]+1.85)
catch e
    warning(['error: ' e.message])
    return
end
if isempty(p.time) || isempty(p.te) || isempty(p.radius) || sum(p.te==0, 'all')
    warning('Empty field in profile!')
    return
end

p.time  = downsamplebymean(p.time, 10);
p.te    = downsamplebymean(p.te,   10);

% for i=1:length(te.time)
%     maxis = sp.maxisloc.sigslice(te.time(i));
%     rmajor = maxis.sigunbund('rmaxis');
%     te.data(i) = pchip(p.radius, p.te(:, i), rmajor);
% end
rmajor = median(sp.maxisloc.sigunbund('rmaxis'));
ind_axis = findvalue(p.radius, rmajor);
te.data = p.te(ind_axis, :);

te.time = p.time;
te.data = te.data*1e-3;
te.status = 1;