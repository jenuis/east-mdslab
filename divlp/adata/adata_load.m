function [data_cell, marker] = adata_load(RootDir, PortList, CollectType, ModeType, FitType, R2Type)
%% check arguments
if nargin == 1
    if ischar(RootDir)
        RootDir = {RootDir};
    end
    data_cell = {};
    for i=1:length(RootDir)
        load(RootDir{i})
        data_cell{end+1} = data;
    end
    marker = RootDir;
    return
end

if ischar(PortList)
    PortList = {PortList};
end

if isempty(ModeType)
    ModeType = {'L', 'H'};
elseif ischar(ModeType)
    ModeType = {ModeType};
end
%% gen DataName
DataName = {};
for i=1:length(ModeType)
    DataName{end+1} = [CollectType '_' upper(ModeType{i}) '_Mode_' FitType '-' R2Type '.mat'];
end
%% initialzie outpyts
data_cell = {};
marker = {};
%% main
for i=1:length(PortList)
    for j=1:length(DataName)
        RelPath = fullfile(PortList{i}, DataName{j});
        file_path = fullfile(RootDir, RelPath);
        marker{end+1} = strrep(RelPath, filesep, '_');
        load(file_path);
        data_cell{end+1} = data;
    end
end