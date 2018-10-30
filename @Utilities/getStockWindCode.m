function cCodes = getStockWindCode(cInitCodes,cType)
% 根据code和type，查找对应的windcode
% 输入：
%   cInitCdes: 数值型或者6位的code代码数组
%   cTtype   : 查找的类型，分为'S','B','F','I','FU'
%              可以分别定义，也可以统一一起定义，默认为'S'
% 输出：
%   codes的cell数组；查找不到的codes；
%  
% 例子：
% Utilities.getStockWindCode([1;2;600340;2648],['S';'S';'S';'F'])  定义all type
% Utilities.getStockWindCode([1;2;600340;2648],'S') 复制定义 type
% Utilities.getStockWindCode([1;2;600340;2648]) 默认type='S'
% - by Neo 2018.03.20
if ~exist('securityinfo','var')
    load('securityinfo.mat');
end
if ~exist('cInitCodes','var')
    error('Must input code list.');        
else
    if isa(cInitCodes,'double')
        cInitCodes = cellstr(num2str(cInitCodes,'%06d'));
    elseif ischar(cInitCodes)
        cInitCodes = cellstr(cInitCodes);
    end
end
if ~exist('cType','var')
    cType=repmat({'S'},size(cInitCodes,1),1);
else
    if size(cType,1)<size(cInitCodes,1)
        if size(cType,1)>1
            error('Must define only one type or all types.');            
        else
            cType=repmat({cType},size(cInitCodes,1),1);
        end
    end
    if ischar(cType)
        cType=cellstr(cType);
    end
end
tpc=cell2table([cInitCodes,cType],'VariableNames',{'code','type'});
tCodes=innerjoin(tpc,securityinfo);
cCodes=tCodes.windcode;

cBadCodes=setdiff(cInitCodes,tCodes.code);
for i=1:length(cBadCodes)
    fprintf('%s do not found in securityinfo \n',cBadCodes{i});
end
end