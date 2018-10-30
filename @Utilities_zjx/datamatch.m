function [dData,dMatchedDates,dMatchedIndecies] = datamatch(cData, varargin)
% ���������ڶ������߶������ݡ�cData��һ��������ɵ�cell��
%           ����cDataΪӵ�ж�Ӧ���ԵĽṹ����ɵ�cell����ʱ'prop'������Ч��
% 
% - by Lary 2016.01.07
%      Lary 2016.01.12 update: ��ѡ����'unionmdates'��������Ʒ��ʱ���ǩ������
%                              ��ѡ����'uniondates'��������Ʒ�����ڱ�ǩ������
%      Lary 2016.01.25 update: ��ѡ����'prop'����һ��char���͵��������ơ�
%                              ����dVol = datamatch(cData,'prop','vol');
%                              ��union��Ч�������֧�֣���
%      Lary 2016.01.26 update: ��ѡ����'minutes'��
%                              �������dMatchedIndecies��¼ÿ�����ڵ�λ�á�
%                              ����������������ݵ�bug��
%      Lary 2016.03.17 update: ������'uniondates'��'unionmdates'ѡ��������
%                              dDataΪ���ݲ�����Ĭ��nan��dMatchedDatesΪ
%                              union��������ڣ�dMatchedIndeciesΪ�߼�����
%                              ������ÿ���ʲ�������dData�ж�Ӧλ�õ���Ϣ��
%                              ����any(isnan(dData(dMatchedIndecies(:,iStock),iStock)))=false�����
%      Lary 2016.05.19 update: ������'nan=prev'��Ϊѡ�������unionʱ������
%                              nanʱ��ǰֵ���浱ǰ��nan��������ǰֵ����ô�
%                              ������ȻΪnan��

nStocks = numel(cData);
bProp = any(strcmpi(varargin,'prop'));
if bProp
    chProp = varargin{find(strcmpi(varargin,'prop'))+1};
end
if any(strcmpi(varargin,'unionmdates'))
    dMatchedDates = cData{1}.mdates;
    for iStock = 2:nStocks
        dMatchedDates = union(dMatchedDates,cData{iStock}.mdates);
    end
    nDates = numel(dMatchedDates);
    dData = nan(nDates,nStocks);
    dMatchedIndecies = false(nDates,nStocks);
    for iStock = 1:nStocks
        
        [bTemp,ixTemp] = ismember(dMatchedDates,cData{iStock}.mdates);
        dMatchedIndecies(:,iStock) = bTemp;
        if any(strcmpi(varargin,'nan=prev'))
            tpixPri = Utilities_zjx.sig2pos(ixTemp,false);
            tpbPri = logical(tpixPri);
            dData(tpbPri,iStock) = cData{iStock}.mclose( tpixPri(tpbPri) );
        else
            dData(bTemp,iStock) = cData{iStock}.mclose( ixTemp(bTemp) );
        end
    end
elseif any(strcmpi(varargin,'uniondates'))
    dMatchedDates = cData{1}.dates;
    for iStock = 2:nStocks
        dMatchedDates = union(dMatchedDates,cData{iStock}.dates);
    end
    nDates = numel(dMatchedDates);
    dData = nan(nDates,nStocks);
    dMatchedIndecies = false(nDates,nStocks);
    for iStock = 1:nStocks
        [bTemp,ixTemp] = ismember(dMatchedDates,cData{iStock}.dates);
        dMatchedIndecies(:,iStock) = bTemp;
        if any(strcmpi(varargin,'nan=prev'))
            tpixPri = Utilities_zjx.sig2pos(ixTemp,false);
            tpbPri = logical(Utilities_zjx.sig2pos(bTemp,false));
            if bProp
                tpData = cData{iStock}.getprop(chProp);
                dData(tpbPri,iStock) = tpData( tpixPri(tpbPri) );
            else
                dData(tpbPri,iStock) = cData{iStock}.close( tpixPri(tpbPri) );
            end
        else
            if bProp
                tpData = cData{iStock}.getprop(chProp);
                dData(bTemp,iStock) = tpData( ixTemp(bTemp) );
            else
                dData(bTemp,iStock) = cData{iStock}.close( ixTemp(bTemp) );
            end
        end
    end
elseif any(strcmpi(varargin,'minutes'))
    dMatchedDates = cData{1}.mdates;
    
    for iStock = 2:nStocks
        dMatchedDates = intersect(dMatchedDates,cData{iStock}.mdates);
    end
    nDates = numel(dMatchedDates);
    iMatchedData = zeros(nDates,nStocks);
    dData = zeros(nDates,nStocks);
    dMatchedIndecies = zeros(nDates,nStocks);
    for iStock = 1:nStocks
        [~,~,iMatchedData(:,iStock)] = intersect(dMatchedDates,cData{iStock}.mdates);
        if bProp && chProp(1) == 'm'
            dTempData = cData{iStock}.getprop(chProp);
            dData(:,iStock) = dTempData(iMatchedData(:,iStock));
            dMatchedIndecies(:,iStock) = iMatchedData(:,iStock);
        else
            dData(:,iStock) = cData{iStock}.mclose(iMatchedData(:,iStock));
            dMatchedIndecies(:,iStock) = iMatchedData(:,iStock);
        end
    end
else
    dMatchedDates = cData{1}.dates;
    
    for iStock = 2:nStocks
        dMatchedDates = intersect(dMatchedDates,cData{iStock}.dates);
    end
    nDates = numel(dMatchedDates);
    iMatchedData = zeros(nDates,nStocks);
    dData = zeros(nDates,nStocks);
    dMatchedIndecies = zeros(nDates,nStocks);
    for iStock = 1:nStocks
        [~,~,iMatchedData(:,iStock)] = intersect(dMatchedDates,cData{iStock}.dates);
        if bProp
            dTempData = cData{iStock}.getprop(chProp);
            dData(:,iStock) = dTempData(iMatchedData(:,iStock));
            dMatchedIndecies(:,iStock) = iMatchedData(:,iStock);
        else
            dData(:,iStock) = cData{iStock}.close(iMatchedData(:,iStock));
            dMatchedIndecies(:,iStock) = iMatchedData(:,iStock);
        end
    end
end

end

