% draw instructions
if ey==1        
    DrawFormattedText(win.hndl, 'LEFT EYE', win.rect(3)*.25, win.rect(4)*.6, [255 255 255]);
else
    DrawFormattedText(win.hndl, 'RIGHT EYE', win.rect(3)*.25, win.rect(4)*.6, [255 255 255]);
end
DrawFormattedText(win.hndl, 'HORIZONTAL TRACE', win.rect(3)*.25, win.rect(4)*.65, horcol);
DrawFormattedText(win.hndl, 'VERTICAL TRACE', win.rect(3)*.25, win.rect(4)*.7, vertcol);

% draw traces
Screen('DrawDots', win.hndl, [xpix; ypix_xraw],2,horcol,[0 0],1);
Screen('DrawDots', win.hndl, [xpix; ypix_yraw],2,vertcol,[0 0],1); 

% draw timescale
Screen('DrawLine', win.hndl, [255 255 255], xpixmin, 1, xpixmin+xpixmax, 1, 2);
Screen('DrawLine', win.hndl, [255 255 255], xpixmin, 1, xpixmin, 10, 2);
Screen('DrawText', win.hndl, num2str(round(tsample(1))), xpixmin, 12);

% draw displacement scale
Screen('DrawLine', win.hndl, [255 255 255], xpixmin-20, ypixmin, xpixmin-20, ypixmin+ypixmax, 2);
Screen('DrawText', win.hndl, num2str(round(smallest_sample)), xpixmin-50, ypixmin-20);
 Screen('DrawText', win.hndl, num2str(round(bigest_sample)), xpixmin-50, ypixmin+ypixmax+5);

% draw box for data
Screen('FrameRect', win.hndl, [55 55 55],[xpixmin-5,ypixmin-5,xpixmin+xpixmax+5,ypixmin+ypixmax+5], 2);
for ii=1:10
    Screen('DrawLine', win.hndl, [255 255 255], xpixmin+xpixmax*(ii/10), 1, xpixmin+xpixmax*(ii/10), 10, 2);
    Screen('DrawText', win.hndl, num2str(round(tsample(round(ii.*length(tsample)./10)))),xpixmin+ xpixmax*(ii/10), 12, [255 255 255]);
end

% draw box for rawcalibpos
Screen('FrameRect', win.hndl, [55 55 55],cuad4Rect, 2)

% draw sampled calibration raw position if exist
if exist('rawCalibToplot')
    if any(rawCalibToplot)
       for pt = 1:size(dotinfo.dot_order,1)
           if ~any(isnan(rawCalibToplot(pt,:)))
               if dotinfo.validation_flag == 0
                    Screen('DrawText', win.hndl,num2str(dotinfo.dot_order(pt)),rawCalibToplot(pt,1),rawCalibToplot(pt,2),[255 255 255]);
               else
                   Screen('DrawText', win.hndl,num2str(dotinfo.dot_order(pt)),rawCalibToplot(pt,1),rawCalibToplot(pt,2),[255 255 0]);
               end
           end
       end
    end
end
% if exist('rawValidToplot')
%     if any(rawValidToplot)
%        for pt = 1:size(dotinfo.dot_order,1)
%            if ~any(isnan(rawValidToplot(pt,:)))
%             Screen('DrawText', win.hndl,num2str(dotinfo.dot_order(pt)),rawValidToplot(pt,1),rawValidToplot(pt,2),[255 255 0]);
%            end
%        end
%     end
% end