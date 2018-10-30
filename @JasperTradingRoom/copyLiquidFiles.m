function copyLiquidFiles()
%收盘后拷贝持仓，成交，权益文件

%需要按日期拷贝的文件夹
roots=[{'E:\交易文档\temp'},{'E:\交易文档\temp\deal'},{'E:\交易文档\temp\tradingDetail'},{'V:\Neo\收盘数据\每日成交明细'}]; %,{'V:\Neo\收盘数据\每日成交'}
targets=[{'V:\Neo\收盘数据\收盘仓位'},{'V:\Neo\收盘数据\每日成交'},{'V:\每日成交单明细'},{'V:\每日成交单明细'}];%,{'V:\每日成交单'}
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
copyfile('E:\交易文档\temp\future','V:\Neo\收盘数据\期货权益');
copyfile('V:\Neo\收盘数据\期货权益','V:\DailyFutureDetail');
copyfile('V:\Neo\收盘数据\收盘仓位','V:\产品持仓');

 
end