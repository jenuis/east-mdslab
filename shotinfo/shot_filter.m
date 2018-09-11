clear
clc
campaign = 2018;
suffix = sprintf('_%i.mat',2018);
load(['data/valid_shot' suffix])
shotlist = [shot_rec{:,1}];
bad_shot_ind = [];
for i=1:length(shotlist)
    shotno = shotlist(i);
    %% read shot info
    shot_para = plasmapara(shotno);
    if isempty(shot_para)
        continue
    end
    sp = plasmapara_mean(shot_para);
    %% record data
    shot_rec{i,3} = sp.flat_time;
    shot_rec{i,4} = sp.it;
    %% record geo
    drsep = proc_geo(shotno, sp.flat_time);
%     if ~drsep.status || abs(drsep.mean) > 40
%         bad_shot_ind(end+1) = i;
%         continue
%     end
    shot_rec{i,5} = drsep.mean;
    %% record powbit
    shot_rec{i,6} = genpowbit(sp);
    %% ne valid
%     ne = proc_ne(shotno, ip.flat_time);
%     if ~ne.status
%         bad_shot_ind(end+1) = i;
%         continue
%     end
end
shot_rec(bad_shot_ind,:)=[];
save(['data/filter_shot' suffix],'shot_rec');