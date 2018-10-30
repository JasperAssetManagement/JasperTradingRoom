function [cDataOut,dMatchedDates,dMatchedIndecies] = dataunion(cData, varargin)
% 本函数用于对齐日线对象的合并开高低收价格。
% 
% - by Lary 2016.11.15

nStocks = numel(cData);
bProp = any(strcmpi(varargin,'prop'));
if bProp
    chProp = varargin{find(strcmpi(varargin,'prop'))+1};
end
if any(strcmpi(varargin,'uniondates'))
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
            dData(tpbPri,iStock) = cData{iStock}.close( tpixPri(tpbPri) );
        else
            dData(bTemp,iStock) = cData{iStock}.close( ixTemp(bTemp) );
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

