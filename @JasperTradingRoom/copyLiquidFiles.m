function copyLiquidFiles()
%收盘后拷贝持仓，成交，权益文件

%需要按日期拷贝的文件夹
roots=[{'\\192.168.1.88\Trading Share\Neo\收盘数据\每日成交明细'}]; %,{'V:\Neo\收盘数据\每日成交'}
targets=[{'\\192.168.1.88\Trading Share\每日成交单明细'}];%,{'V:\每日成交单'}
for i=1:length(roots)
    fileroot=roots{i};
    if ~strcmp(fileroot(end),'\')
        fileroot=strcat(fileroot,'\');
    end
    filelist = dir(fileroot);
    for j = 1:length(filelist)
        cnts=0;
        if (strcmp(filelist(j).name,'.') || strcmp(filelist(j).name,'..') || filelist(j).isdir)
            continue;            
        end
        if floor(filelist(j).datenum) == today()
            copyfile(strcat(fileroot,filelist(j).name),targets{i});            
        end        
    end
end

%可一次性拷贝的文件夹
copyfile('\\192.168.1.88\Trading Share\Neo\收盘数据\期货权益','\\192.168.1.88\Trading Share\DailyFutureDetail');
copyfile('\\192.168.1.88\Trading Share\Neo\收盘数据\收盘仓位','\\192.168.1.88\Trading Share\产品持仓');

 
end