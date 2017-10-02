function [xgaz,ygaz] = correct_raw(ux,uy,xraw,yraw);

xgaz = ux'*[ones(1,size(xraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
ygaz = uy'*[ones(1,size(yraw',2));xraw';yraw';xraw'.^2;yraw'.^2];
