function dailysettlement()
%dailysettlement ÿ���̺������Զ����ƹ���
% 
% - by Lary 2017.05.14 version 0.0.1

%% ����/����

% ����ԭʼ�ļ�·��
% posdir = 'C:\Users\DELL\Desktop\Models\��Ʒ�ֲ�\';
% tradedir = 'C:\Users\DELL\Desktop\Models\ÿ�ճɽ���\';
% margindir = 'C:\Users\DELL\Desktop\Models\�ڻ�Ȩ��\';
fcsettledir = 'Z:\һ���̺�鵵\';
% orderdir = 'C:\Users\DELL\Desktop\Models\�µ�����\';

% Ŀ���ļ�·��
postgt = 'Z:\��Ʒ�ֲ�\';
tradetgt = 'Z:\ÿ�ճɽ���\';
margintgt = 'Z:\DailyFutureDetail\';
detailstgt='Z:\ÿ�ճɽ�����ϸ\';

% һ���ļ�����Ϣ
fcpos = '�ۺ���Ϣ��ѯ_���֤ȯ.xls';
fcsettle = '�ۺ���Ϣ��ѯ_�ɽ��ر�.xls';
fcmargin = '�ڻ���֤�����.xls';
fcdetails='�ۺ���Ϣ��ѯ_�ɽ��ر���ϸ.xls';

% ��Ʒ��Ϣ��
tInfo = JStrading.getproductinfo;

%% ����
zjx = Utilities_zjx;
dToday = zjx.tradingdate(today());

if dToday == today() && hour(now)<4
    
end

%% һ������
tpCurrentDir = cd();
chWinrarDir = 'C:\Program Files\WinRAR';
soursezipdir = fcsettledir;
zipfile = [datestr(dToday,'yyyymmdd') '.zip'];
unziptgtdir = soursezipdir;
if exist([soursezipdir zipfile],'file')
    % ��ѹ��
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

    % ���������
    tpsdir = dir(todayunzipdir);
    tpt = struct2table(tpsdir);
    tpt.Properties.VariableNames(strcmpi(tpt.Properties.VariableNames,'name'))={'fcremark'};
    tFiles = innerjoin(tpt,tInfo);
    tFiles = tFiles(logical(tFiles.isfc),:);
    cChecklist = tInfo.fcremark(logical(tInfo.isfc));
    bMissing = ~ismember(cChecklist,tFiles.fcremark);
    if any(bMissing)
        fprintf('��ע�⣬����һ����Ʒ��Ϣȱʧ��\n')
        disp(cChecklist(bMissing))
    end
    
    % ��ƥ��ɹ��Ĳ�Ʒ����ѭ��
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
            % �ֲ��ļ�
            tpsource = [todayunzipdir tFiles.fcremark{iFile} '\' fcpos];
            tptgt = [postgt tFiles.name{iFile} fcptype];
            bSuccess = copyfile(tpsource,tptgt,'F');
            if ~bSuccess
                warning([tptgt '����ʧ��'])
            end
            % �ɽ�
%             tpsource = [todayunzipdir tFiles.fcremark{iFile} '\' fcsettle];
%             %tptgt = [tradetgt tFiles.name{iFile} '�ɽ�' fcstype];
%             bSuccess = copyfile(tpsource,tptgt,'F');
%             if ~bSuccess
%                 warning([tptgt '����ʧ��'])
%             end
            % �ڻ�Ȩ��
            tpsource = [todayunzipdir tFiles.fcremark{iFile} '\' fcmargin];
            tptgt = [margintgt tFiles.margintype{iFile} '_' tFiles.id{iFile} '_' tFiles.name{iFile} fcmtype];
            bSuccess = copyfile(tpsource,tptgt,'F');
            if ~bSuccess
                warning([tptgt '����ʧ��'])
            end
            % �ɽ���ϸ
            tpsource = [todayunzipdir tFiles.fcremark{iFile} '\' fcdetails];
            tptgt = [detailstgt tFiles.name{iFile} '�ɽ���ϸ' fcmtype];
              bSuccess = copyfile(tpsource,tptgt,'F');
            if ~bSuccess
                warning([tptgt '����ʧ��'])
            end        
        catch err %#ok
            warning([tFiles.fcremark{iFile} '�ɽ����ڻ�����ʧ��'])
        end
    end
    % ɾ����ʱĿ¼ �ص�ԭʼ·��
    rmdir(todayunzipdir,'s')
else
    warning('δ�ҵ�һ���̺������ļ�')
end
fprintf('\n')

% %% ����ÿ�չ�Ʊ�����µ��ļ�
% spos = dir(orderdir);
% tptfiles = struct2table(spos);
% tptfiles = tptfiles(~tptfiles.isdir,:);
% nFiles = numel(tptfiles.name);
% 
% % ����ļ��޸�����
% bToday = fix(tptfiles.datenum)==dToday;
% if any(~bToday)
%     fprintf('��ע�⣬�����ļ��������°汾��\n')
%     disp(tptfiles.name(~bToday))
% end
% 
% % �����ڹ鵵�����Ƶ�Ŀ��Ŀ¼
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
%         warning(['�ļ�' tptfiles.name{iFile} '����ʧ��'])
%     end
% end
% fprintf('\n')
% 
% %% ���Ƴֲ��ļ�
% spos = dir(posdir);
% tptfiles = struct2table(spos);
% tptfiles = tptfiles(~tptfiles.isdir,:);
% nFiles = numel(tptfiles.name);
% 
% % ����ļ��޸�����
% bToday = fix(tptfiles.datenum)==dToday;
% if any(~bToday)
%     fprintf('��ע�⣬�����ļ��������°汾��\n')
%     disp(tptfiles.name(~bToday))
% end
% 
% % ����ļ���ȫ
% cA = tInfo.name(~tInfo.isfc);
% cF = cellfun(@(x)[x '�ڻ�'],tInfo.name(logical(tInfo.futures)),'UniformOutput',false);
% cH = cellfun(@(x)([x 'H��']),tInfo.name(logical(tInfo.hstock)),'UniformOutput',false);
% cChecklist = [cA;cH;cF];
% 
% cFiles = cellfun(@(x)strsplit(x,'.'),tptfiles.name,'UniformOutput',false);
% cFiles = cellfun(@(x)x{1},cFiles,'UniformOutput',false);
% bMissing = ~ismember(cChecklist,cFiles);
% if any(bMissing)
%     fprintf('��ע�⣬���³ֲ��ļ�ȱʧ��\n')
%     disp(cChecklist(bMissing))
% end
% 
% % �����ڹ鵵�����Ƶ�Ŀ��Ŀ¼
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
%         warning(['�ļ�' tptfiles.name{iFile} '����ʧ��'])
%     end
% end
% fprintf('\n')
% 
% %% ���Ƴɽ��ļ�
% strade = dir(tradedir);
% tptfiles = struct2table(strade);
% tptfiles = tptfiles(~tptfiles.isdir,:);
% nFiles = numel(tptfiles.name);
% 
% % ����ļ��޸�����
% bToday = fix(tptfiles.datenum)==dToday;
% if any(~bToday)
%     fprintf('��ע�⣬�����ļ��������°汾��\n')
%     disp(tptfiles.name(~bToday))
% end
% 
% % ����ļ���ȫ
% cA = cellfun(@(x)[x '�ɽ�'],tInfo.name(~tInfo.isfc),'UniformOutput',false);
% cH = cellfun(@(x)[x '�۹ɳɽ�'],tInfo.name(logical(tInfo.hstock)),'UniformOutput',false);
% cF = cellfun(@(x)[x '�ڻ��ɽ�'],tInfo.name(logical(tInfo.futset)),'UniformOutput',false);
% cChecklist = [cA;cH;cF];
% 
% cFiles = cellfun(@(x)strsplit(x,'.'),tptfiles.name,'UniformOutput',false);
% cFiles = cellfun(@(x)x{1},cFiles,'UniformOutput',false);
% bMissing = ~ismember(cChecklist,cFiles);
% if any(bMissing)
%     fprintf('��ע�⣬���³ɽ��ļ�ȱʧ��\n')
%     disp(cChecklist(bMissing))
% end
% 
% % �����ڹ鵵�����Ƶ�Ŀ��Ŀ¼
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
%         warning(['�ļ�' tptfiles.name{iFile} '����ʧ��'])
%     end
% end
% fprintf('\n')
% 
% %% �����ڻ�Ȩ��
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
%     fprintf('��ע�⣬�����ļ��޷�ƥ���ڻ�Ȩ�����ͣ�\n')
%     disp(tptfiles.name(~ismember(cFiles,tFiles.name)))
% end
% 
% % ����ļ��޸�����
% bToday = fix(tptfiles.datenum)==dToday;
% if any(~bToday)
%     fprintf('��ע�⣬�����ļ��������°汾��\n')
%     disp(tptfiles.name(~bToday))
% end
% 
% % ����ļ���ȫ
% cChecklist = tInfo.name(~tInfo.isfc);
% 
% bMissing = ~ismember(cChecklist,cFiles);
% if any(bMissing)
%     fprintf('��ע�⣬�����ڻ�Ȩ���ļ�ȱʧ��\n')
%     disp(cChecklist(bMissing))
% end
% 
% % �����ڹ鵵�����Ƶ�Ŀ��Ŀ¼
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
%         warning(['�ļ�' tFiles.name{iFile} '����ʧ��'])
%     end
% end

end