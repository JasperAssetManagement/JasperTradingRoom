function dailysettlement()
%dailysettlement 每日盘后数据自动复制工具
% 
% - by Lary 2017.05.14 version 0.0.1

%% 常量/输入

% 本地原始文件路径
% posdir = 'C:\Users\DELL\Desktop\Models\产品持仓\';
% tradedir = 'C:\Users\DELL\Desktop\Models\每日成交单\';
% margindir = 'C:\Users\DELL\Desktop\Models\期货权益\';
fcsettledir = 'Z:\一创盘后归档\';
% orderdir = 'C:\Users\DELL\Desktop\Models\下单汇总\';

% 目标文件路径
postgt = 'Z:\产品持仓\';
tradetgt = 'Z:\每日成交单\';
margintgt = 'Z:\DailyFutureDetail\';
detailstgt='Z:\每日成交单明细\';

% 一创文件名信息
fcpos = '综合信息查询_组合证券.xls';
fcsettle = '综合信息查询_成交回报.xls';
fcmargin = '期货保证金分析.xls';
fcdetails='综合信息查询_成交回报明细.xls';

% 产品信息表
tInfo = JStrading.getproductinfo;

%% 工具
zjx = Utilities_zjx;
dToday = zjx.tradingdate(today());

if dToday == today() && hour(now)<4
    
end

%% 一创处理
tpCurrentDir = cd();
chWinrarDir = 'C:\Program Files\WinRAR';
soursezipdir = fcsettledir;
zipfile = [datestr(dToday,'yyyymmdd') '.zip'];
unziptgtdir = soursezipdir;
if exist([soursezipdir zipfile],'file')
    % 解压缩
    cd(chWinrarDir)
    try
        todayunzipdir = [unziptgtdir datestr(dToday,'yyyymmdd') '\'];
        if exist(todayunzipdir,'dir')
            rmdir(todayunzipdir,'s')
        end
        dos(['winrar x -r ' soursezipdir zipfile ' ' unziptgtdir]);
        cd(tpCurrentDir)
    catch err %#ok
        cd(tpCurrentDir)
    end

    % 检查完整性
    tpsdir = dir(todayunzipdir);
    tpt = struct2table(tpsdir);
    tpt.Properties.VariableNames(strcmpi(tpt.Properties.VariableNames,'name'))={'fcremark'};
    tFiles = innerjoin(tpt,tInfo);
    tFiles = tFiles(logical(tFiles.isfc),:);
    cChecklist = tInfo.fcremark(logical(tInfo.isfc));
    bMissing = ~ismember(cChecklist,tFiles.fcremark);
    if any(bMissing)
        fprintf('请注意，以下一创产品信息缺失：\n')
        disp(cChecklist(bMissing))
    end
    
    % 按匹配成功的产品进行循环
    nFiles = numel(tFiles.fcremark);
    
    fcptype = strsplit(fcsettle,'.');
    fcptype = ['.' fcptype{end}];
    fcstype = strsplit(fcsettle,'.');
    fcstype = ['.' fcstype{end}];
    fcmtype = strsplit(fcmargin,'.');
    fcmtype = ['.' fcmtype{end}];
    fcdtype = strsplit(fcdetails,'.');
    fcdtype = ['.' fcdtype{end}];
    for iFile = 1:nFiles
        try
            % 持仓文件
            tpsource = [todayunzipdir tFiles.fcremark{iFile} '\' fcpos];
            tptgt = [postgt tFiles.name{iFile} fcptype];
            bSuccess = copyfile(tpsource,tptgt,'F');
            if ~bSuccess
                warning([tptgt '复制失败'])
            end
            % 成交
%             tpsource = [todayunzipdir tFiles.fcremark{iFile} '\' fcsettle];
%             %tptgt = [tradetgt tFiles.name{iFile} '成交' fcstype];
%             bSuccess = copyfile(tpsource,tptgt,'F');
%             if ~bSuccess
%                 warning([tptgt '复制失败'])
%             end
            % 期货权益
            tpsource = [todayunzipdir tFiles.fcremark{iFile} '\' fcmargin];
            tptgt = [margintgt tFiles.margintype{iFile} '_' tFiles.id{iFile} '_' tFiles.name{iFile} fcmtype];
            bSuccess = copyfile(tpsource,tptgt,'F');
            if ~bSuccess
                warning([tptgt '复制失败'])
            end
            % 成交明细
            tpsource = [todayunzipdir tFiles.fcremark{iFile} '\' fcdetails];
            tptgt = [detailstgt tFiles.name{iFile} '成交明细' fcmtype];
              bSuccess = copyfile(tpsource,tptgt,'F');
            if ~bSuccess
                warning([tptgt '复制失败'])
            end        
        catch err %#ok
            warning([tFiles.fcremark{iFile} '成交或期货复制失败'])
        end
    end
    % 删除临时目录 回到原始路径
    rmdir(todayunzipdir,'s')
else
    warning('未找到一创盘后清算文件')
end
fprintf('\n')

% %% 复制每日股票批量下单文件
% spos = dir(orderdir);
% tptfiles = struct2table(spos);
% tptfiles = tptfiles(~tptfiles.isdir,:);
% nFiles = numel(tptfiles.name);
% 
% % 检查文件修改日期
% bToday = fix(tptfiles.datenum)==dToday;
% if any(~bToday)
%     fprintf('请注意，以下文件不是最新版本：\n')
%     disp(tptfiles.name(~bToday))
% end
% 
% % 按日期归档并复制到目标目录
% chTodayOrderDir = [orderdir datestr(dToday,'yyyymmdd') '\'];
% if ~exist(chTodayOrderDir,'dir')
%     mkdir(chTodayOrderDir)
% end
% 
% for iFile = 1:nFiles
%     tpsource = [orderdir tptfiles.name{iFile}];
%     tpdest1 = [chTodayOrderDir tptfiles.name{iFile}];
%     bSuccess = movefile(tpsource,tpdest1);
%     if ~bSuccess
%         warning(['文件' tptfiles.name{iFile} '复制失败'])
%     end
% end
% fprintf('\n')
% 
% %% 复制持仓文件
% spos = dir(posdir);
% tptfiles = struct2table(spos);
% tptfiles = tptfiles(~tptfiles.isdir,:);
% nFiles = numel(tptfiles.name);
% 
% % 检查文件修改日期
% bToday = fix(tptfiles.datenum)==dToday;
% if any(~bToday)
%     fprintf('请注意，以下文件不是最新版本：\n')
%     disp(tptfiles.name(~bToday))
% end
% 
% % 检查文件齐全
% cA = tInfo.name(~tInfo.isfc);
% cF = cellfun(@(x)[x '期货'],tInfo.name(logical(tInfo.futures)),'UniformOutput',false);
% cH = cellfun(@(x)([x 'H股']),tInfo.name(logical(tInfo.hstock)),'UniformOutput',false);
% cChecklist = [cA;cH;cF];
% 
% cFiles = cellfun(@(x)strsplit(x,'.'),tptfiles.name,'UniformOutput',false);
% cFiles = cellfun(@(x)x{1},cFiles,'UniformOutput',false);
% bMissing = ~ismember(cChecklist,cFiles);
% if any(bMissing)
%     fprintf('请注意，以下持仓文件缺失：\n')
%     disp(cChecklist(bMissing))
% end
% 
% % 按日期归档并复制到目标目录
% chTodayPosDir = [posdir datestr(dToday,'yyyymmdd') '\'];
% if ~exist(chTodayPosDir,'dir')
%     mkdir(chTodayPosDir)
% end
% 
% for iFile = 1:nFiles
%     tpsource = [posdir tptfiles.name{iFile}];
%     tpdest1 = [chTodayPosDir tptfiles.name{iFile}];
%     tpdest2 = [postgt tptfiles.name{iFile}];
%     bSuccess1 = copyfile(tpsource,tpdest1,'F');
%     bSuccess2 = copyfile(tpsource,tpdest2,'F');
%     if ~bSuccess1 || ~bSuccess2
%         warning(['文件' tptfiles.name{iFile} '复制失败'])
%     end
% end
% fprintf('\n')
% 
% %% 复制成交文件
% strade = dir(tradedir);
% tptfiles = struct2table(strade);
% tptfiles = tptfiles(~tptfiles.isdir,:);
% nFiles = numel(tptfiles.name);
% 
% % 检查文件修改日期
% bToday = fix(tptfiles.datenum)==dToday;
% if any(~bToday)
%     fprintf('请注意，以下文件不是最新版本：\n')
%     disp(tptfiles.name(~bToday))
% end
% 
% % 检查文件齐全
% cA = cellfun(@(x)[x '成交'],tInfo.name(~tInfo.isfc),'UniformOutput',false);
% cH = cellfun(@(x)[x '港股成交'],tInfo.name(logical(tInfo.hstock)),'UniformOutput',false);
% cF = cellfun(@(x)[x '期货成交'],tInfo.name(logical(tInfo.futset)),'UniformOutput',false);
% cChecklist = [cA;cH;cF];
% 
% cFiles = cellfun(@(x)strsplit(x,'.'),tptfiles.name,'UniformOutput',false);
% cFiles = cellfun(@(x)x{1},cFiles,'UniformOutput',false);
% bMissing = ~ismember(cChecklist,cFiles);
% if any(bMissing)
%     fprintf('请注意，以下成交文件缺失：\n')
%     disp(cChecklist(bMissing))
% end
% 
% % 按日期归档并复制到目标目录
% chTodayTrade = [tradedir datestr(dToday,'yyyymmdd') '\'];
% if ~exist(chTodayTrade,'dir')
%     mkdir(chTodayTrade)
% end
% 
% for iFile = 1:nFiles
%     tpsource = [tradedir tptfiles.name{iFile}];
%     tpdest1 = [chTodayTrade tptfiles.name{iFile}];
%     tpdest2 = [tradetgt tptfiles.name{iFile}];
%     bSuccess1 = copyfile(tpsource,tpdest1,'F');
%     bSuccess2 = copyfile(tpsource,tpdest2,'F');
%     if ~bSuccess1 || ~bSuccess2
%         warning(['文件' tptfiles.name{iFile} '复制失败'])
%     end
% end
% fprintf('\n')
% 
% %% 复制期货权益
% smargin = dir(margindir);
% tptfiles = struct2table(smargin);
% tptfiles = tptfiles(~tptfiles.isdir,:);
% cFiles = cellfun(@(x)strsplit(x,'.'),tptfiles.name,'UniformOutput',false);
% cFiles = cellfun(@(x)x{1},cFiles,'UniformOutput',false);
% tFiles = tptfiles;
% tFiles.filename = tFiles.name;
% tFiles.name = cFiles;
% tFiles = innerjoin(tFiles,tInfo);
% if numel(tFiles.name)<numel(cFiles)
%     fprintf('请注意，以下文件无法匹配期货权益类型：\n')
%     disp(tptfiles.name(~ismember(cFiles,tFiles.name)))
% end
% 
% % 检查文件修改日期
% bToday = fix(tptfiles.datenum)==dToday;
% if any(~bToday)
%     fprintf('请注意，以下文件不是最新版本：\n')
%     disp(tptfiles.name(~bToday))
% end
% 
% % 检查文件齐全
% cChecklist = tInfo.name(~tInfo.isfc);
% 
% bMissing = ~ismember(cChecklist,cFiles);
% if any(bMissing)
%     fprintf('请注意，以下期货权益文件缺失：\n')
%     disp(cChecklist(bMissing))
% end
% 
% % 按日期归档并复制到目标目录
% chTodayMargin = [margindir datestr(dToday,'yyyymmdd') '\'];
% if ~exist(chTodayMargin,'dir')
%     mkdir(chTodayMargin)
% end
% 
% nFiles = numel(tFiles.name);
% for iFile = 1:nFiles
%     tpsource = [margindir tFiles.filename{iFile}];
%     tpdest1 = [chTodayMargin tFiles.margintype{iFile} '_' tFiles.id{iFile} '_' tFiles.filename{iFile}];
%     tpdest2 = [margintgt tFiles.margintype{iFile} '_' tFiles.id{iFile} '_' tFiles.filename{iFile}];
%     bSuccess1 = copyfile(tpsource,tpdest1,'F');
%     bSuccess2 = copyfile(tpsource,tpdest2,'F');
%     if ~bSuccess1 || ~bSuccess2
%         warning(['文件' tFiles.name{iFile} '复制失败'])
%     end
% end

end