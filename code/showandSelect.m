function [calibraw,calibsac] = showandSelect(win,calibraw,calibsac,dotinfo)
%sca

for ey = 1:length(calibsac)
    if ey == 1, col = [0 0 255];, else col = [255 0 0];,end
    sampleStartDot = find(calibraw(ey).time>dotinfo.tstart_dots,1,'first');
    dotTime = calibraw(ey).time(1,sampleStartDot:end)-dotinfo.tstart_dots;
    xsample = calibraw(ey).rawx(1,sampleStartDot:end);
    xsample(xsample==win.el.MISSING_DATA | xsample<prctile(xsample,[5]) | xsample>prctile(xsample,[95])) = NaN;
    xsample = xsample - min(xsample);
    Screen('DrawDots', win.hndl, [.05*win.rect(3)+dotTime/dotTime(end)*.9*win.rect(3);...
       .1*win.rect(4) + xsample./max(xsample).*win.rect(4)./4],2,col,[0 0],1);  %uncorrected data
end
Screen('Flip', win.hndl);
sca
