function copyLiquidFiles()
%���̺󿽱��ֲ֣��ɽ���Ȩ���ļ�

%��Ҫ�����ڿ������ļ���
roots=[{'\\192.168.1.88\Trading Share\Neo\��������\ÿ�ճɽ���ϸ'}]; %,{'V:\Neo\��������\ÿ�ճɽ�'}
targets=[{'\\192.168.1.88\Trading Share\ÿ�ճɽ�����ϸ'}];%,{'V:\ÿ�ճɽ���'}
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

%��һ���Կ������ļ���
copyfile('\\192.168.1.88\Trading Share\Neo\��������\�ڻ�Ȩ��','\\192.168.1.88\Trading Share\DailyFutureDetail');
copyfile('\\192.168.1.88\Trading Share\Neo\��������\���̲�λ','\\192.168.1.88\Trading Share\��Ʒ�ֲ�');

 
end