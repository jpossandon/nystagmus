function [xgaz,ygaz] = correct_raw(xraw,yraw,caldata)

xgazaux = caldata.ux'*[ones(1,size(xraw'-caldata.rawCenter(1),2));xraw'-caldata.rawCenter(1);yraw'-caldata.rawCenter(2);(xraw'-caldata.rawCenter(1)).^2;(yraw'-caldata.rawCenter(2)).^2];
ygazaux = caldata.uy'*[ones(1,size(yraw'-caldata.rawCenter(2),2));xraw'-caldata.rawCenter(1);yraw'-caldata.rawCenter(2);(xraw'-caldata.rawCenter(1)).^2;(yraw'-caldata.rawCenter(2)).^2];

if strcmp(caldata.calibType,'HV9')
    xgaz    = nan(1,length(xgazaux));
    ygaz    = nan(1,length(ygazaux));
    for ii = 1:4
        switch ii   %cuadrants
            case 1
                auxindx = find(xgazaux<0 & ygazaux<0);
            case 2
                auxindx = find(xgazaux>0 & ygazaux<0);
            case 3
                auxindx = find(xgazaux<0 & ygazaux>0);
            case 4
                auxindx = find(xgazaux>0 & ygazaux>0);
        end
        xgaz(auxindx) = xgazaux(auxindx)+caldata.m(ii).*xgazaux(auxindx).*ygazaux(auxindx);
        ygaz(auxindx) = ygazaux(auxindx)+caldata.n(ii).*xgazaux(auxindx).*ygazaux(auxindx);
    end
else
    xgaz = xgazaux;
    ygaz = ygazaux;
end
xgaz    = xgaz+caldata.rect(3)/2;
ygaz    = (ygaz+caldata.rect(4)/2);
    