function [dData,dMatchedDates,dMatchedIndecies] = datamatch(cData, varargin)
% 本函数用于对齐日线对象数据。cData是一个对象组成的cell。
%           或者cData为拥有对应属性的结构体组成的cell，此时'prop'功能无效。
% 
% - by Lary 2016.01.07
%      Lary 2016.01.12 update: 可选输入'unionmdates'返回所有品种时间标签并集。
%                              可选输入'uniondates'返回所有品种日期标签并集。
%      Lary 2016.01.25 update: 可选输入'prop'加上一个char类型的属性名称。
%                              例：dVol = datamatch(cData,'prop','vol');
%                              对union无效（待添加支持）。
%      Lary 2016.01.26 update: 可选输入'minutes'。
%                              增加输出dMatchedIndecies记录每个日期的位置。
%                              修正了输出错误数据的bug。
%      Lary 2016.03.17 update: 增加了'uniondates'和'unionmdates'选项的输出。
%                              dData为数据并集，默认nan。dMatchedDates为
%                              union过后的日期，dMatchedIndecies为逻辑变量
%                              包含了每个资产数据在dData中对应位置的信息。
%                              即：any(isnan(dData(dMatchedIndecies(:,iStock),iStock)))=false恒成立
%      Lary 2016.05.19 update: 增加了'nan=prev'作为选项。适用于union时，存在
%                              nan时用前值代替当前的nan。（如无前值，则该处
%                              数据仍然为nan）

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

