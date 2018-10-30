function []=ImportFutureInfo(filesroot,tradeDate,f_updateDB)
%�����ڻ�Ȩ������

clear IDSymbol;
IDSymbol.key=[];
IDSymbol.id=[];
fid = fopen('importIDSymbol.txt');
while ~feof(fid)
    rowData = fgetl(fid);
    rowData = regexp( rowData, '=', 'split' );
    IDSymbol.key=[IDSymbol.key;rowData(1)];
    IDSymbol.id=[IDSymbol.id;rowData(2)];
    %IDSymbol(rowData{1})=rowData{2};
end  

clear fuData;   
fuData.id=[];
fuData.frozen=[];
fuData.available=[];
fuData.asset=[];

readParamsMap=containers.Map;
readParamsMap('1')={{'�˺�','��ǰ��֤��','�����ʽ�'},','; % ƥ���������ָ���
                    {'��Ʒ����','ռ�ñ�֤��','���ñ�֤��'},'","';
                    {'��������','ռ�ñ�֤��','���ñ�֤��'},'","';
                    {'�ʲ���Ԫ���','ռ�ñ�֤��(ʵʱ)','׼����֤��'},'","';
                    {'��Ʒ����','�ڻ�ռ�ñ�֤��','�ڻ����ñ�֤��'},'","';
                    };    
readParamsMap('2')={{'�ʽ��˺�','��ĩ���ᱣ֤��','�����ʽ�'},3,10; % ƥ����������ȡ����(header, rowdata)
                    {'��Ʒ','ռ�ñ�֤��','���ñ�֤��'},1,10; %2
                    {'�ʽ��ʺ�','���ձ�֤��ռ��','ʵʱ����'},5,6;
                    {'��������','ռ�ñ�֤��(ʵʱ)','��֤�����'},1,10; %2
                    {'��Ʒ����','�ڻ�ռ�ñ�֤��','�ڻ����ñ�֤��'},1,2;
                    [3,22,20],3,3
                    }; 
readParamsMap('3')={{'��֤��:','��ǰȨ��:'},2; % ƥ����������������(header, rowdata)
                    {'�ܱ�֤��:','��̬Ȩ��:'},2;
                    };
readParamsMap('4')={{'Report','Account',{'UseMargin','Available'}} % xml�Ĳ㼶�ṹ
                    };                
if ~strcmp(filesroot(end),'\')
    filesroot=strcat(filesroot,'\');
end
filelist = dir(filesroot);
for j = 1:length(filelist)
    if (strcmp(filelist(j).name,'.') || strcmp(filelist(j).name,'..') || filelist(j).isdir)
        continue;            
    end
    fprintf('Info(%s): ���ڴ��� %s .\n',datestr(now(),0),filelist(j).name);
    params=regexp(filelist(j).name,'_','split');
    if strcmp(params{1},'1') %csv �ĵ���ѶͶ,O32)
        p=readParamsMap(params{1}); 
        [key, frozen, available]=csvimport(strcat(filesroot,filelist(j).name),'columns',p{str2double(params{2}),1},'delimiter',p{str2double(params{2}),2},'outputAsChar',true);                                   
        key=regexprep(key,'[",\s]','');
        frozen=regexprep(frozen,'[",\s]','');
        available=regexprep(available,'[",\s]','');
        %ȥ�������ļ����������еĻ�����
        frozen(cellfun(@isempty,key))=[];
        available(cellfun(@isempty,key))=[];
        key(cellfun(@isempty,key))=[];
        [isin, rows]=ismember(key,IDSymbol.key);

        if sum(isin==0)>0
            fprintf('δ�����˻��ļ���%s δ����ID��%s \n',filelist(j).name,key{find(isin==0)});                 
        end
        if sum(isin==1)>0
            id=IDSymbol.id(rows(isin==1));          
            try
                [isin,rows]=ismember(id,fuData.id);
            catch err
                isin=0;
            end
            if sum(isin==0)>0
                fuData.id=[fuData.id;id(find(isin==0))];
                fuData.frozen=[fuData.frozen;cellfun(@str2double,frozen(find(isin==0)))];
                fuData.available=[fuData.available;cellfun(@str2double,available(find(isin==0)))]; 
            else
                fuData.frozen(rows(isin==1))=fuData.frozen(rows(isin==1))+cellfun(@str2double,frozen(find(isin==1)));
                fuData.available(rows(isin==1))=fuData.available(rows(isin==1))+cellfun(@str2double,available(find(isin==1)));
            end
        end
    end

    if strcmp(params{1},'2') %excel �ĵ�(�����ʹ�)
        p=readParamsMap(params{1});            
        if isnumeric(p{str2double(params{2}),1})
            rowData = read_excel_columns(strcat(filesroot,filelist(j).name),1,p{str2double(params{2}),2},p{str2double(params{2}),3},...
                'columns',p{str2double(params{2}),1},'outputAsChar',true);
            data=rowData;
        else
            rowData = read_excel_columns(strcat(filesroot,filelist(j).name),1,p{str2double(params{2}),2},p{str2double(params{2}),3},'outputAsChar',true);
            [isin, cols]=ismember(p{str2double(params{2}),1},rowData(1,:));
            colData=rowData(2:end,cols(isin==1));
            rows=cellfun(@(x)((ischar(x)||isscalar(x)&&~isnan(x))),colData(:,1));
            data=colData(rows,:);
        end
        [isin, rows]=ismember(data(:,1),IDSymbol.key);
        if sum(isin==0)>0
            fprintf('δ�����˻��ļ���%s δ����ID��%s \n',filelist(j).name,data{1});     
            return;
        end
        if sum(isin==1)>0
            id=IDSymbol.id(rows(isin==1));          
            try
                [isin,rows]=ismember(id,fuData.id);
            catch err
                isin=0;
            end           
            if sum(isin==0)>0
                fuData.id=[fuData.id;id(find(isin==0))];
                fuData.frozen=[fuData.frozen;cell2mat(data(find(isin==0),2))];
                fuData.available=[fuData.available;cell2mat(data(find(isin==0),3))];                
            else
                fuData.frozen(rows(isin==1))=fuData.frozen(rows(isin==1))+cell2mat(data(find(isin==1),2));
                fuData.available(rows(isin==1))=fuData.available(rows(isin==1))+cell2mat(data(find(isin==1),3));
            end
        end
    end

    if strcmp(params{1},'3') %�ı� �ĵ�(���״�ʦ)
        p=readParamsMap(params{1});
        fid=fopen(strcat(filesroot,filelist(j).name));            
        rowData = textscan(fid,'%s%f','Headerlines',p{str2double(params{2}),2});
        fclose(fid);
        [isin, cols]=ismember(p{str2double(params{2}),1},rowData{1});
        data=rowData{2}(cols(isin==1));
        fuData.id=[fuData.id;params{3}];
        fuData.frozen=[fuData.frozen;data(1)];
        fuData.available=[fuData.available;data(2)-data(1)];            
    end    

    if strcmp(params{1},'4') %xml 
        p=readParamsMap(params{1});
        rowData = xml2struct(strcat(filesroot,filelist(j).name));
        p_lvl=p{str2double(params{2})};
        levels=size(p_lvl,2);
        for i=1:levels-1
            rowData=rowData.(p_lvl{i});
        end 
        fuData.id=[fuData.id;params{3}];
        fuData.frozen=[fuData.frozen;str2double(regexprep(rowData.(p_lvl{levels}{1}).Text,'[,]',''))];
        fuData.available=[fuData.available;str2double(regexprep(rowData.(p_lvl{levels}{2}).Text,'[,]',''))];            
    end   

end
fuData.asset=fuData.frozen+fuData.available;
inputValue=[];
for i=1:length(fuData.id)
    inputValue=[inputValue;{tradeDate},fuData.id(i),fuData.asset(i),fuData.available(i),fuData.frozen(i)];      
end


if 1==f_updateDB    
    conn=database('JasperDB','TraderOnly','112358.qwe','com.microsoft.sqlserver.jdbc.SQLServerDriver','jdbc:sqlserver://192.168.1.88:1433;databaseName=JasperDB');
    res = upsert(conn,'JasperDB.dbo.AccountDetail',{'Trade_dt','Account','FutureAsset','FutureAvailable','FutureFrozen'},[1 1 0 0 0],inputValue);     
    
    fprintf('insert %d,update %d \n',sum(res==1),sum(res==0));
end



   