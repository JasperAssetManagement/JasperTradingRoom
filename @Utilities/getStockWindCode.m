function cCodes = getStockWindCode(cInitCodes,cType)
% ����code��type�����Ҷ�Ӧ��windcode
% ���룺
%   cInitCdes: ��ֵ�ͻ���6λ��code��������
%   cTtype   : ���ҵ����ͣ���Ϊ'S','B','F','I','FU'
%              ���Էֱ��壬Ҳ����ͳһһ���壬Ĭ��Ϊ'S'
% �����
%   codes��cell���飻���Ҳ�����codes��
%  
% ���ӣ�
% Utilities.getStockWindCode([1;2;600340;2648],['S';'S';'S';'F'])  ����all type
% Utilities.getStockWindCode([1;2;600340;2648],'S') ���ƶ��� type
% Utilities.getStockWindCode([1;2;600340;2648]) Ĭ��type='S'
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