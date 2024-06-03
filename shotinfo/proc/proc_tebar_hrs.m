function [te, p] = proc_tebar_hrs(shotno, time_range)
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
    p.loadbycal(time_range, [-0.13 0.5]+1.85)
%     p.loadbycal(time_range)
    p.sortbyradius
catch e
    warning(['error: ' e.message])
    return
end
if isempty(p.time) || isempty(p.te) || isempty(p.radius)
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

te.time = p.time;

rmajor.time = sp.maxisloc.time;
rmajor.data = sp.maxisloc.sigunbund('rmaxis');
res = efit_map(sp.shotno, [], 1 ,[], 1, sp.EfitTree);
rlcfs.time = res.time;
rlcfs.data = res.lcfs_mid_r;

te.data = zeros(size(te.time));
for i=1:length(te.time)
    t = te.time(i);
    Rc = pchip(rmajor.time, rmajor.data, t);
    Rsep = pchip(rlcfs.time, rlcfs.data, t);
    
    r = linspace(Rc, Rsep, 100);
    T = pchip(p.radius, p.te(:,i), r);
    
    Tavg = trapz(r, T)/(Rsep-Rc);
    te.data(i) = Tavg;
end

te.data = te.data*1e-3; % keV
te.status = 1;