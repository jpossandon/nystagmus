[FileName,PathName,FilterIndex] = uigetfile('C:\EXPERIMENTS\OSSANDON\newtest\*');

if contains(PathName,'horizntal') || contains(PathName,'horizontal')
    stype = 'horizontal';
elseif contains(PathName,'center')
     stype = 'center';
elseif contains(PathName,'vertical')
     stype = 'vertical';
end
if FilterIndex
    read_nysatagmus_tests(fullfile(PathName,FileName),stype)
end
[path,NAME]  = fileparts(FileName);
copyfile(fullfile(PathName,[NAME '_' stype '.pdf']),'C:\Users\Experimenter\Desktop\nystagmusReports\');
close all
exit