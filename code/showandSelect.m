function [output_x,output_y,output_time,accept,start_time,end_time] = showandSelect(win,calibraw,calibsac)

save('test1','calibraw','calibsac')

% setup display colors
horcol         = [0 0 255];
vertcol        = [0 255 0];
horcol_select  = [0 255 255];
vertcol_select = [255 255 0];

for ey=1:2
    
    Screen('FillRect', win.hndl, win.bkgcolor);
    
    accept=0;

    while ~accept
        
        % load samples
        xsample = calibraw(ey).rawx;
        ysample = calibraw(ey).rawy;

        % remove missing values
        xsample(abs(xsample)==30000 | abs(xsample)==32768) = nan;
        ysample(abs(ysample)==30000 | abs(ysample)==32768) = nan;
        
        % baseline to smallest value   
        % both traces now also have the same scale
        smallest_sample = min([min(xsample) min(ysample)]);
        xsample = xsample - smallest_sample;
        ysample = ysample - smallest_sample;


        % make display box limits
        xpixmin = .05*win.rect(3);
        xpixmax = .90*win.rect(3);
        ypixmin = .10*win.rect(4);
        ypixmax = .25*win.rect(4);

        % create xvalues
        xpix = linspace(xpixmin,xpixmax,length(xsample));

        % create yvalues from percentage of sample range
        ypix_xraw =  ypixmin + (xsample./max(xsample)).* ypixmax;
        ypix_yraw =  ypixmin + (ysample./max(xsample)).* ypixmax;

        % draw samples
        Screen('DrawDots', win.hndl, [xpix; ypix_xraw],2,horcol,[0 0],1);
        Screen('DrawDots', win.hndl, [xpix; ypix_yraw],2,vertcol,[0 0],1);  %uncorrected data
        if ey==1        
            DrawFormattedText(win.hndl, 'LEFT EYE', win.rect(3)*.25, win.rect(4)*.6, [255 255 255]);
        else
            DrawFormattedText(win.hndl, 'RIGHT EYE', win.rect(3)*.25, win.rect(4)*.6, [255 255 255]);
        end
        DrawFormattedText(win.hndl, 'HORIZONTAL TRACE', win.rect(3)*.25, win.rect(4)*.65, horcol);
        DrawFormattedText(win.hndl, 'VERTICAL TRACE', win.rect(3)*.25, win.rect(4)*.7, vertcol);
        Screen('Flip', win.hndl);

        %%% draw saccades (import eyelink values)
        if 0
            for sacc=1:length(calibsac) 
            
                %sacc_start = calibsac.

                % saccade startxy
                % saccad  end xy
                % transform x's exactly like xsamples
                % transform y's exactly like ysamples
                % transform timestamps exactly like dottime
                % time = x
                % xy   = y
                
                % plot line
                % plot end-circle
            end
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        starts = nan;
        ends   = nan;
        ShowCursor;
        while isnan(starts) || isnan(ends)
            
            % get mouse click
            [~, mx, ~, buttons] = GetClicks;

            if buttons==1 && mx>xpixmin && mx<xpixmax && isnan(starts)
                % if mouse click within box
                % go from pixel value to sample index
                [~, starts] = min(abs(xpix-mx));
                buttons=0;
                mx_start=mx;
            end

            if buttons==1 && mx>mx_start && mx<xpixmax && ~isnan(starts) 
                [~, ends] = min(abs(xpix-mx));
            end  
            
        end
        HideCursor;
        
        % select samples from timestamp indexes
        xsample_select=xsample(starts:ends);
        ysample_select=ysample(starts:ends);

        xpix_select      =  xpix(starts:ends);%xpixmin + (dottime_select./max(dottime)) .* xpixmax;
        ypix_xraw_select =  ypixmin + (xsample_select./max(xsample)) .* ypixmax;
        ypix_yraw_select =  ypixmin + (ysample_select./max(xsample)) .* ypixmax;

        %%% --------------------------------
        % same change as above (equalize range for y to x)
        
        
        % draw uncorrected data again
        Screen('DrawDots', win.hndl, [xpix; ypix_xraw],2,horcol,[0 0],1);
        Screen('DrawDots', win.hndl, [xpix; ypix_yraw],2,vertcol,[0 0],1);
        % draw selected range of samples
        Screen('DrawDots', win.hndl, [xpix_select; ypix_xraw_select],2,horcol_select,[0 0],1);
        Screen('DrawDots', win.hndl, [xpix_select; ypix_yraw_select],2,vertcol_select,[0 0],1);    
        Screen('DrawLine', win.hndl, [255 255 255], xpix_select(1), ypixmin, xpix_select(1), ypixmax*2, 1);
        Screen('DrawLine', win.hndl, [255 255 255], xpix_select(end), ypixmin, xpix_select(end), ypixmax*2, 1);
        if ey==1        
            DrawFormattedText(win.hndl, 'LEFT EYE', win.rect(3)*.25, win.rect(4)*.6, [255 255 255]);
        else
            DrawFormattedText(win.hndl, 'RIGHT EYE', win.rect(3)*.25, win.rect(4)*.6, [255 255 255]);
        end
        DrawFormattedText(win.hndl, 'HORIZONTAL TRACE', win.rect(3)*.25, win.rect(4)*.65, horcol);
        DrawFormattedText(win.hndl, 'VERTICAL TRACE', win.rect(3)*.25, win.rect(4)*.7, vertcol);
        Screen('Flip', win.hndl);

        % accept selection?
        FlushEvents;
        [secs, keyCode, deltaSecs] = KbWait;
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
%     calibsac(ey,starts:ends)    = 1;

    start_time                  = calibraw(ey).time(1);
    end_time                    = calibraw(ey).time(end);
    
    
end % for each ey










