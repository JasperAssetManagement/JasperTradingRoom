function copyLiquidFiles()

roots=[{'\\192.168.1.88\Trading Share\Neo\收盘数据\每日成交明细\'}];
targets=[{'\\192.168.1.88\Trading Share\每日成交单明细\'}];
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

copyfile('\\192.168.1.88\Trading Share\Neo\收盘数据\收盘仓位\','\\192.168.1.88\Trading Share\产品持仓\');
 
end