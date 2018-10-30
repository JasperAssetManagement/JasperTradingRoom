function initSecurityInfo()
% 更新各个标的的基本信息，包括stock,bond,fund,future
% 输出：
%   securityinfo.mat
%  
% 例子：
%      Utilities.initSecurityInfo(); 
% - by Neo 2018.03.01
% get data from wind DB
jtr=JasperTradingRoom;

if ~exist('date','var')
   date=datestr(today(),'yyyymmdd');
end

conn=jtr.db85conn;
sql=['SELECT [S_INFO_WINDCODE],[S_INFO_CODE],[S_INFO_NAME],''S'' FROM [WINDFILESYNC].[dbo].[ASHAREDESCRIPTION] ' ...
'where S_INFO_DELISTDATE is null or S_INFO_DELISTDATE>=''' date '''' ...
' union ' ...
'SELECT [S_INFO_WINDCODE],[S_INFO_CODE],[S_INFO_NAME],''FU'' FROM [WINDFILESYNC].[dbo].[CFUTURESDESCRIPTION] ' ...
'where S_INFO_DELISTDATE is null or S_INFO_DELISTDATE>=''' date '''' ...
' union ' ...
'SELECT [S_INFO_WINDCODE],SUBSTRING([S_INFO_WINDCODE],1,CHARINDEX(''.'',[S_INFO_WINDCODE])-1),[S_INFO_NAME],''B'' FROM [WINDFILESYNC].[dbo].[CBONDDESCRIPTION] ' ...
'where B_INFO_DELISTDATE is null or B_INFO_DELISTDATE>=''' date ''''];
data=Utilities.getsqlrtn(conn,sql);
securityinfo=cell2table(data,'VariableNames',{'windcode','code','name','type'});

save('securityinfo.mat','securityinfo');

end