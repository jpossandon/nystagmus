function [data,type] = get_ETdataraw

datatypes = [3:9,24,25,28,200];
while 1
    type = Eyelink('GetNextDataType');
    if find(datatypes==type)
        %data = Eyelink( 'GetFloatDataRaw',type,1);
        data = Eyelink( 'GetFloatData',type);
        break
    end
end
