clsall

% campaign = 2017;
campaign = 2018;
switch campaign
    case 2018
        shotlist = 76144:81692; % 2018 last campaign
    case 2017
        shotlist = 71801:75716; % 2017 last campaign
    case 2016
        shotlist = 65577:71800; % 2016 last campaign
    case 2015
        shotlist = 53047:57583; % 2015 05 campaign
    otherwise
        return
end

curr_dir = strsplit( mfilename('fullpath'), filesep );
curr_dir = strjoin(curr_dir(1:end-1),filesep);
addpath([curr_dir filesep 'supports'])


shot_rec = {};

for i=1:length(shotlist)
    %% get current shot number
    shotno = shotlist(i);
    disp(['shot: ' num2str(shotno)])
    %% check ip
    ip = proc_ip(shotno);
    if ~ip.status
        continue
    end
    %% check it
    %% check ne
    %% check power
    %% save shots
    shot_rec{end+1, 1} = shotno;
    shot_rec{end, 2} = ip.mean;
    %% show separater line    
    disp('-------------------------------------------------------------------------------------------------------------')
end
save(['data/valid_shot_' num2str(campaign) '.mat'],'shot_rec','-v7.3')