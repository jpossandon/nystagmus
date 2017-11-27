function [output_x,output_y,output_time,accept,start_time,end_time] = showandSelect(win,calibraw,calibsac)

save('test1','calibraw','calibsac')

% setup display colors
horcol         = [0 0 255];
vertcol        = [0 255 0];
horcol_select  = [0 255 255];
vertcol_select = [255 255 0];



for ey=1:2
    
    Screen('FillRect', win.hndl, win.bkgcolor);
    
    % to confirm selected sample sequence
    accept=0;
    % if we want to cancel and collect a new sample sequence
    abortselection = 0;
    while ~accept && ~abortselection
        
        % load samples
        xsample = calibraw(ey).rawx;
        ysample = calibraw(ey).rawy;
        tsample = calibraw(ey).time-calibraw(ey).time(1);
        
        % remove missing values
        xmiss     = abs(xsample)==30000 | abs(xsample)==32768;
        ymiss     = abs(ysample)==30000 | abs(ysample)==32768;
        for rmv = 1:4   % remove four valuea around missing
            xmiss = sum([xmiss;[diff(xmiss) 0];[0 fliplr(diff(fliplr(xmiss)))]]~=0)>0;
            ymiss = sum([ymiss;[diff(ymiss) 0];[0 fliplr(diff(fliplr(ymiss)))]]~=0)>0;
        end
        xsample(xmiss) = nan;
        ysample(ymiss) = nan;
        % and center it
        xsample = xsample-nanmedian(xsample);
        ysample = ysample-nanmedian(ysample);
        
        % baseline to smallest value   
        % both traces now also have the same scale
        smallest_sample = min([min(xsample) min(ysample)]);
        xsample     = xsample - smallest_sample;
        ysample     = ysample - smallest_sample;
        bigest_sample = max([max(xsample) max(ysample)]);
        % make display box limits
        xpixmin = .05*win.rect(3);
        xpixmax = .90*win.rect(3);
        ypixmin = .05*win.rect(4);
        ypixmax = .40*win.rect(4);

        % create xvalues
        % teh problem here is that values are not well spaced
         xpix = linspace(xpixmin,xpixmin+xpixmax,length(xsample));
         
        % create xyvalues from percentage of sample range
        ypix_xraw =  ypixmin + (xsample./max(bigest_sample)).* ypixmax;
        ypix_yraw =  ypixmin + (ysample./max(bigest_sample)).* ypixmax;

        
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
        
        % draw box for data
        Screen('FrameRect', win.hndl, [55 55 55],[xpixmin-5,ypixmin-5,xpixmin+xpixmax+5,ypixmin+ypixmax+5], 2);
        for ii=1:10
            Screen('DrawLine', win.hndl, [255 255 255], xpixmin+xpixmax*(ii/10), 1, xpixmin+xpixmax*(ii/10), 10, 2);
            Screen('DrawText', win.hndl, num2str(round(tsample(round(ii.*length(tsample)./10)))),xpixmin+ xpixmax*(ii/10), 12, [255 255 255]);
        end
        
        if isstruct(calibsac)
            if ey == 1 || (ey==2 && length(calibsac)==2)
                saccades = [calibsac(ey).start' calibsac(ey).end' calibsac(ey).gstx' calibsac(ey).genx' ...
                             calibsac(ey).gsty' calibsac(ey).geny' calibsac(ey).eye'];
                %%% draw saccades
                for sacc=1:size(saccades,1) 
                    if saccades(sacc,7)==ey
                        % find sample index of saccade start and end
                        [~,sacc_start_index] = min(abs(calibraw(ey).time-calibsac(ey).start(sacc)));
                        [~,sacc_end_index]   = min(abs(calibraw(ey).time-calibsac(ey).end(sacc)));

                        % find screen coordinates for this saccade
                        sacc_start = xpix(sacc_start_index);
                        sacc_end   = xpix(sacc_end_index);                

%                         sacc_xst   = ypix_xraw(sacc_start_index); 
                         sacc_xen   = ypix_xraw(sacc_end_index);
%                         sacc_yst   = ypix_yraw (sacc_start_index); 
%                         sacc_yen   = ypix_yraw (sacc_end_index); 
                        
                        Screen('DrawDots', win.hndl, [xpix(sacc_start_index:sacc_end_index); ypix_xraw(sacc_start_index:sacc_end_index)],2,[255 127 127],[0 0],1);
                        Screen('DrawDots', win.hndl, [xpix(sacc_start_index:sacc_end_index); ypix_yraw(sacc_start_index:sacc_end_index)],2,[255 127 127],[0 0],1); 
                        
%                         Screen('DrawLine', win.hndl, [255 255 255], sacc_start, sacc_xst, sacc_end, sacc_xen, 3);
                        Screen('DrawDots', win.hndl, [sacc_end; sacc_xen], 15, [255 255 255], [], 2);
                    end
                end
            end
        end
        Screen('Flip', win.hndl);
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        starts = nan;
        ends   = nan;
        ShowCursor;
        while isnan(starts) || isnan(ends) || abortselection==1
            
            % get mouse click
            [~, mx, ~, buttons] = GetClicks;

            if buttons==1 && mx>xpixmin && mx<xpixmin+xpixmax && isnan(starts)
                % if mouse click within box
                % go from pixel value to sample index
                [~, starts] = min(abs(xpix-mx));
                buttons=0;
                mx_start=mx;
            end

            if buttons==1 && mx>mx_start && mx<xpixmin+xpixmax && ~isnan(starts) 
                [~, ends] = min(abs(xpix-mx));
            end  
            
            [keyIsDown,~,keyCode] = KbCheck;
             if keyIsDown
                if keyCode(KbName('BackSpace'))        
                    abortselection = 1;
                end
             end            
            
        end
        HideCursor;
        
        % select samples from timestamp indexes
        xsample_select=xsample(starts:ends);
        ysample_select=ysample(starts:ends);

        xpix_select      =  xpix(starts:ends);
        ypix_xraw_select =  ypixmin + (xsample_select./max(bigest_sample)) .* ypixmax;
        ypix_yraw_select =  ypixmin + (ysample_select./max(bigest_sample)) .* ypixmax;

        if ey==1        
            DrawFormattedText(win.hndl, 'LEFT EYE', win.rect(3)*.25, win.rect(4)*.6, [255 255 255]);
        else
            DrawFormattedText(win.hndl, 'RIGHT EYE', win.rect(3)*.25, win.rect(4)*.6, [255 255 255]);
        end
        DrawFormattedText(win.hndl, 'HORIZONTAL TRACE', win.rect(3)*.25, win.rect(4)*.65, horcol);
        DrawFormattedText(win.hndl, 'VERTICAL TRACE', win.rect(3)*.25, win.rect(4)*.7, vertcol);        
        % draw uncorrected data again
        Screen('DrawDots', win.hndl, [xpix; ypix_xraw],2,horcol,[0 0],1);
        Screen('DrawDots', win.hndl, [xpix; ypix_yraw],2,vertcol,[0 0],1);
        % draw selected range of samples
        Screen('DrawDots', win.hndl, [xpix_select; ypix_xraw_select],2,horcol_select,[0 0],1);
        Screen('DrawDots', win.hndl, [xpix_select; ypix_yraw_select],2,vertcol_select,[0 0],1);    
        Screen('DrawLine', win.hndl, [255 255 255], xpix_select(1), ypixmin, xpix_select(1), ypixmin+ypixmax, 1);
        Screen('DrawLine', win.hndl, [255 255 255], xpix_select(end), ypixmin, xpix_select(end), ypixmin+ypixmax, 1);

        % draw timescale
        Screen('DrawLine', win.hndl, [255 255 255], xpixmin, 1, xpixmin+xpixmax, 1, 2);
        Screen('DrawLine', win.hndl, [255 255 255], xpixmin, 1, xpixmin, 10, 2);
        Screen('DrawText', win.hndl, num2str(round(tsample(1))), xpixmin, 12);
        
        % draw box
        Screen('FrameRect', win.hndl, [55 55 55],[xpixmin-5,ypixmin-5,xpixmin+xpixmax+5,ypixmin+ypixmax+5], 2);
        for ii=1:10
            Screen('DrawLine', win.hndl, [255 255 255], xpixmin+xpixmax*(ii/10), 1, xpixmin+xpixmax*(ii/10), 10, 2);
            Screen('DrawText', win.hndl, num2str(round(tsample(round(ii.*length(tsample)./10)))),xpixmin+ xpixmax*(ii/10), 12, [255 255 255]);
        end
        
        %%% draw saccades
         if isstruct(calibsac)
            if ey == 1 || (ey==2 && length(calibsac)==2)
                for sacc=1:size(saccades,1) 
                    if saccades(sacc,7)==ey
                        % find sample index of saccade start and end
                        [~,sacc_start_index] = min(abs(calibraw(ey).time-calibsac(ey).start(sacc)));
                        [~,sacc_end_index]   = min(abs(calibraw(ey).time-calibsac(ey).end(sacc)));

                        % find screen coordinates for this saccade
                        sacc_start = xpix(sacc_start_index);
                        sacc_end   = xpix(sacc_end_index);                

                        sacc_xst   = ypix_xraw(sacc_start_index); 
                        sacc_xen   = ypix_xraw(sacc_end_index);

                        Screen('DrawLine', win.hndl, [255 255 255], sacc_start, sacc_xst, sacc_end, sacc_xen, 3);
                        Screen('DrawDots', win.hndl, [sacc_end; sacc_xen], 15, [255 255 255], [], 2);
                    end
                end
            end
         end
        Screen('Flip', win.hndl);

        % accept selection?
        FlushEvents;
        [~, keyCode, ~] = KbWait;
        if keyCode(KbName('Space'))
            accept=1;
        elseif keyCode(KbName('BackSpace'))
            break;    
        end

    end % accept

    if ~accept
        output_time=[];
        output_x=[];
        output_y=[];
        start_time=[];
        end_time=[];
        break
    end
    
    if ey==1
        output_time = nan(2,length(calibraw(ey).rawx));
        output_x    = nan(2,length(calibraw(ey).rawx));
        output_y    = nan(2,length(calibraw(ey).rawx));
    end

    % output the selected samples
    output_time(ey,starts:ends) = calibraw(ey).time(starts:ends);
    output_x(ey,starts:ends)    = calibraw(ey).rawx(starts:ends);                                   %px,py are raw data, gx,gy gaze data; hx,hy headref, data from both eye might be included. The easiest would be to use the uncalibrated GAZE gx,gy data             
    output_y(ey,starts:ends)    = calibraw(ey).rawy(starts:ends);

    start_time                  = calibraw(ey).time(1);
    end_time                    = calibraw(ey).time(end);
    
    
end % for each ey










