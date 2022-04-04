%% Method for reading auxilary heating signals
% -------------------------------------------------------------------------
% Copyright 2019 Xiang Liu
% Contact: Xiang Liu, xliu.fusion@outlook.com
% This file is part of EAST-MDSLAB. You should have recieved a copy of the
% MIT license. If not, see <https://mit-license.org>
% -------------------------------------------------------------------------
function aux_heat = aux_read(shotno, heat_type, exception)
%% config
if nargin == 1
    heat_type = 'all';
    exception = {};
elseif nargin == 2
    exception = {};
end
if ischar(exception)
    exception = {exception};
end
%% call aux read accordingly
if shotno <= 44326 % 2012 campaign
    aux_heat =  aux_read_2012(shotno, heat_type, exception);
else % campaign starts from 2014
    aux_heat =  aux_read_2014(shotno, heat_type, exception);
end
aux_heat.shotno = shotno;


function aux_heat = aux_read_2012(shotno, heat_type, exception)
aux_heat = struct();
%% ecrh
% if ~haselement(exception, 'ech') && haselement({'raw', 'all','ech'}, heat_type)
%     aux_heat.ech = struct();
% end
%% icrf
if ~haselement(exception, 'icrf') && haselement({'raw', 'all','icrf'}, heat_type)
    aux_heat = icrf_read_2012(aux_heat, shotno, heat_type, exception);
end
%% lhw
if ~haselement(exception, 'lhw') && haselement({'raw', 'all','lhw'}, heat_type)
    lhw = signal_read(shotno, 'east_1',    {'plhi', 'plhr'});
    if ~haselement(exception, 'plhi') && fieldexist(lhw, 'plhi') && lhw.plhi.status
        plhi = signal_downsample(lhw.plhi);
        plhr = signal_downsample(lhw.plhr);
        if strcmp(heat_type, 'raw') || judge_pulse(plhi)
            aux_heat.lhw.plhi = plhi;
            aux_heat.lhw.plhr = plhr;
        end
    end
end
%% nbi
% if ~haselement(exception, 'nbi') && haselement({'raw', 'all','nbi'}, heat_type)
%     aux_heat.nbi = struct();
% end

function aux_heat = icrf_read_2012(aux_heat, shotno, heat_type, exception)
node_list = {'icrf1', 'icrf3', 'icrf5', 'icrf7'};
icrf = signal_read(shotno, 'power_east', node_list);
for i=1:length(node_list)
    node_name = node_list{i}(2:end);
    if ~haselement(exception, node_name) && fieldexist(icrf, node_name) && icrf.(node_name).status
        tmp = signal_downsample(icrf.(node_name));
        if strcmp(heat_type, 'raw') || judge_pulse(tmp)
            aux_heat.icrf.(node_name) = tmp;
        end
    end
end

function aux_heat = aux_read_2014(shotno, heat_type, exception)
aux_heat = struct();
%% ecrh
if ~haselement(exception, 'ech') && haselement({'raw', 'all','ech'}, heat_type)
    ech = signal_read(shotno, 'ecrh_east', {'pecrh1i', 'pecrh3i'});
    if ~haselement(exception, 'pecrh1i') && fieldexist(ech, 'pecrh1i') && ech.pecrh1i.status
        pecrh1i = signal_downsample(ech.pecrh1i);
        if strcmp(heat_type, 'raw') || judge_pulse(pecrh1i)
            aux_heat.ech.pecrh1i = pecrh1i;
        end
    end
    if ~haselement(exception, 'pecrh3i') && fieldexist(ech, 'pecrh3i') && ech.pecrh3i.status
        pecrh3i = signal_downsample(ech.pecrh3i);
        if strcmp(heat_type, 'raw') || judge_pulse(pecrh3i)
            aux_heat.ech.pecrh3i = pecrh3i;
        end
    end
end
%% icrf
if ~haselement(exception, 'icrf') && haselement({'raw', 'all','icrf'}, heat_type)
    icrf = signal_read(shotno, 'icrf_east', {'picrfii', 'picrfbi'});
    if ~haselement(exception, 'picrfii') && fieldexist(icrf, 'picrfii') && icrf.picrfii.status 
        picrfii = signal_downsample(icrf.picrfii);
        if strcmp(heat_type, 'raw') || judge_pulse(picrfii)
            aux_heat.icrf.picrfii = picrfii;
        end
    end
    if ~haselement(exception, 'picrfbi') && fieldexist(icrf, 'picrfbi') && icrf.picrfbi.status
        picrfbi = signal_downsample(icrf.picrfbi);
        if strcmp(heat_type, 'raw') || judge_pulse(picrfbi)
            aux_heat.icrf.picrfbi = picrfbi;
        end
    end
end
%% lhw
if ~haselement(exception, 'lhw') && haselement({'raw', 'all','lhw'}, heat_type)
    lhw = signal_read(shotno, 'east_1',    {'plhi1', 'plhi2', 'plhr1', 'plhr2'});
    if ~haselement(exception, 'plhi1') && fieldexist(lhw, 'plhi1') && lhw.plhi1.status
        plhi1 = signal_downsample(lhw.plhi1);
        plhr1 = signal_downsample(lhw.plhr1);
        if strcmp(heat_type, 'raw') || judge_pulse(plhi1)
            aux_heat.lhw.plhi1 = plhi1;
            aux_heat.lhw.plhr1 = plhr1;
        end
    end
    if ~haselement(exception, 'plhi2') && fieldexist(lhw, 'plhi2') && lhw.plhi2.status
        plhi2 = signal_downsample(lhw.plhi2);
        plhr2 = signal_downsample(lhw.plhr2);
        if strcmp(heat_type, 'raw') || judge_pulse(plhi2)
            aux_heat.lhw.plhi2 = plhi2;
            aux_heat.lhw.plhr2 = plhr2;
        end
    end
end
%% nbi
if ~haselement(exception, 'nbi') && haselement({'raw', 'all','nbi'}, heat_type)
    nbi1  = signal_read(shotno, 'nbi_east',  {'pnbi1rsource', 'pnbi1lsource'});
    nbi2  = signal_read(shotno, 'nbi_east',  {'pnbi2rsource', 'pnbi2lsource'});
    if haselement(exception, 'nbi1') || ~strcmp(heat_type, 'raw') && fieldexist(nbi1, 'pnbi1lsource') && ~judge_pulse(nbi1.pnbi1lsource)
        nbi1 = rmfield(nbi1, 'pnbi1lsource');
    end
    if haselement(exception, 'nbi1') || ~strcmp(heat_type, 'raw') && fieldexist(nbi1, 'pnbi1rsource') && ~judge_pulse(nbi1.pnbi1rsource)
        nbi1 = rmfield(nbi1, 'pnbi1rsource');
    end
    if haselement(exception, 'nbi2') || ~strcmp(heat_type, 'raw') && fieldexist(nbi2, 'pnbi2lsource') && ~judge_pulse(nbi2.pnbi2lsource)
        nbi2 = rmfield(nbi2, 'pnbi2lsource');
    end
    if haselement(exception, 'nbi2') || ~strcmp(heat_type, 'raw') && fieldexist(nbi2, 'pnbi2rsource') && ~judge_pulse(nbi2.pnbi2rsource)
        nbi2 = rmfield(nbi2, 'pnbi2rsource');
    end
    nbi1 = signal_downsample( signal_merge(nbi1)); 
    nbi2 = signal_downsample( signal_merge(nbi2));
    if nbi1.status
        aux_heat.nbi.nbi1 = nbi1;
    end
    if nbi2.status
        aux_heat.nbi.nbi2 = nbi2;
    end
end


function valid_pow = judge_pulse(pow_signal, valid_power_range, minimal_time)
if nargin == 1
    valid_power_range = [100 4000];
    minimal_time = 0.3;
elseif nargin == 2
    minimal_time = 0.3;
end
pow_signal = signal_slice(pow_signal, [0 pow_signal.time(end)]);
% valid_pow = max(pow_signal.data) > least_power && haspulse(pow_signal.data);
dt = mean(diff(pow_signal.time));
valid_pow_ind_min = find(pow_signal.data >= valid_power_range(1));
valid_pow_ind_max = find(pow_signal.data >= valid_power_range(2));
valid_pow = 1;
% valid_pow = valid_pow && haspulse(pow_signal.data);
valid_pow = valid_pow &&...
    length(valid_pow_ind_min)*dt >= minimal_time &&...
    length(valid_pow_ind_max)*dt <= minimal_time;
