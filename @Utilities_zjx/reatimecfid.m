function reatimecfid(chCon)
%% reatimecfid实时查看


if nargin==0
    chCon = 'L1701';
end

w = windmatlab;
zjx = Utilities_zjx;
dToday = zjx.tradingdate(today);
chStart = [datestr(dToday,'yyyy-mm-dd') ' 08:59:00'];
chCon_wind = zjx.getwindcode(chCon);
[O1,~,~,O2]=w.wst(chCon_wind,'bsize1,asize1,bid1,ask1,volume,last',chStart,datestr(dToday+15/24,'yyyy-mm-dd HH:MM:SS'));
% [O1,~,~,O2]=w.wst(chCon_wind,'bsize1,asize1,bid1,ask1,volume,last',chStart,datestr(dToday+9.5/24,'yyyy-mm-dd HH:MM:SS'));
tData = array2table([O2,O1],'VariableNames',{'TIME','BV1','SV1','B1','S1','Q','LASTPX'});
tData.CQ = diff([0;tData.Q]);

% tData = tData(tData.TIME<dToday + 9.5/24,:);

tps1 = [0;tData.S1];
tpb1 = [inf;tData.B1];
tp = (double(diff(tpb1)>0 & tData.LASTPX == tData.B1)-double(diff(tps1)<0 & tData.LASTPX == tData.S1)).*tData.CQ;
tpcf = (double(tData.LASTPX>=tData.S1)-double(tData.LASTPX<=tData.B1)).*tData.CQ;
tptcf = (double(tData.LASTPX>=tData.S1)-double(tData.LASTPX<=tData.B1));
tpmix = tp;
tpmix(tp==0) = tpcf(tp==0);
tpcfnet = tpcf;
tpcfnet(tp~=0) = 0;

figure
% tpfh = plotyy(O2,cumsum(tpcf),O2,cumsum(tptcf));
tpfh = plotyy(O2,cumsum(tpcf),O2,tData.LASTPX);
datetick('x','HH:MM')
tpfh(1).XLim = O2([1 end]);
tpfh(2).XLim = O2([1 end]);
end