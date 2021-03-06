function sout = posanalysis(dpos,dDates,varargin)
% 持仓分析
% 
% - by Lary 2017.01.23

% 日均持仓数量
% 日均仓位
% 日均换手率
% 日均多头仓位
% 日均空头仓位
% 空仓概率

sout.nasset = mean(sum(double(logical(dpos)),2));
sout.meanpos = mean(sum(abs(dpos),2));
sout.meannetpos = mean(sum(dpos,2));
sout.meanturnover = mean(sum(abs(diff(dpos)),2));
tppos = dpos;
tppos(dpos<0) = 0;
sout.meanposlong = mean(sum(abs(tppos),2));
tppos = dpos;
tppos(dpos>0) = 0;
sout.meanposshort = mean(sum(abs(tppos),2));
sout.pholding = mean(any(logical(dpos),2));

if exist('dDates','var')
    sout.seansonmean = [mean(dpos(quarter(dDates)==1,:));...
                    mean(dpos(quarter(dDates)==2,:));...
                    mean(dpos(quarter(dDates)==3,:));...
                    mean(dpos(quarter(dDates)==4,:))];
    sout.seansonchg = [mean(logical(diff(dpos(quarter(dDates)==1,:))));...
                    mean(logical(diff(dpos(quarter(dDates)==2,:))));...
                    mean(logical(diff(dpos(quarter(dDates)==3,:))));...
                    mean(logical(diff(dpos(quarter(dDates)==4,:))))];
    sout.monthmean = [mean(dpos(month(dDates)==1,:));...
                    mean(dpos(month(dDates)==2,:));...
                    mean(dpos(month(dDates)==3,:));...
                    mean(dpos(month(dDates)==4,:));...
                    mean(dpos(month(dDates)==5,:));...
                    mean(dpos(month(dDates)==6,:));...
                    mean(dpos(month(dDates)==7,:));...
                    mean(dpos(month(dDates)==8,:));...
                    mean(dpos(month(dDates)==9,:));...
                    mean(dpos(month(dDates)==10,:));...
                    mean(dpos(month(dDates)==11,:));...
                    mean(dpos(month(dDates)==12,:))];
    sout.monthchg = [mean(logical(diff(dpos(month(dDates)==1,:))));...
                    mean(logical(diff(dpos(month(dDates)==2,:))));...
                    mean(logical(diff(dpos(month(dDates)==3,:))));...
                    mean(logical(diff(dpos(month(dDates)==4,:))));...
                    mean(logical(diff(dpos(month(dDates)==5,:))));...
                    mean(logical(diff(dpos(month(dDates)==6,:))));...
                    mean(logical(diff(dpos(month(dDates)==7,:))));...
                    mean(logical(diff(dpos(month(dDates)==8,:))));...
                    mean(logical(diff(dpos(month(dDates)==9,:))));...
                    mean(logical(diff(dpos(month(dDates)==10,:))));...
                    mean(logical(diff(dpos(month(dDates)==11,:))));...
                    mean(logical(diff(dpos(month(dDates)==12,:))))];
    sout.seansonexp = [mean(abs(dpos(quarter(dDates)==1,:)));...
                    mean(abs(dpos(quarter(dDates)==2,:)));...
                    mean(abs(dpos(quarter(dDates)==3,:)));...
                    mean(abs(dpos(quarter(dDates)==4,:)))];
    sout.monthexp = [mean(abs(dpos(month(dDates)==1,:)));...
                    mean(abs(dpos(month(dDates)==2,:)));...
                    mean(abs(dpos(month(dDates)==3,:)));...
                    mean(abs(dpos(month(dDates)==4,:)));...
                    mean(abs(dpos(month(dDates)==5,:)));...
                    mean(abs(dpos(month(dDates)==6,:)));...
                    mean(abs(dpos(month(dDates)==7,:)));...
                    mean(abs(dpos(month(dDates)==8,:)));...
                    mean(abs(dpos(month(dDates)==9,:)));...
                    mean(abs(dpos(month(dDates)==10,:)));...
                    mean(abs(dpos(month(dDates)==11,:)));...
                    mean(abs(dpos(month(dDates)==12,:)))];
end

end