function read_nysatagmus_tests(filename,type)

[trial,meta] =totrial(filename,{'raw','gaze'});
[PATHSTR,NAME,EXT]  = fileparts(filename);
sFc = meta.sF/1000;
%%

        % center, vertical and horizontal test consists in three trials, first when the left eye
        % closed (30s), second with the right eye closed (30s), and third both eyes
        % open (60s)
        %
        %
        titlelabels = {'RightEye','LeftEye','BothEye'};
%         fignames    = {[type,'Right_Eye'],[type,'Left_Eye'],[type,'Both_Eye']};
        fignames    = [NAME '_' type]; 
        colors = [1 0 0;0 0 1];
        eyes = {'left','right'};
        nsamplesPerPlot = 30000;
        if strcmpi(type,'center')
            ttrials =1;
        else
            ttrials =3;
        end
        
        for corbsl = 1:2
            
            for tr = 1:3

                if tr == 3
                    sbp = 3;      % number of subplots for differents eyes and velocity
                    plt = 2;
                    eye = [1,2];
                elseif tr == 2
                    sbp = 3;
                    plt = 1;
                    eye = 1;
                elseif tr == 1
                    if strcmpi(type,'center')   % girst trial center is 3 minutes?
                        plt = 6;
                        eye = 2;
                        sbp = 3;
                    else
                        sbp = 3;
                        plt = 1;
                        eye = 2;
                    end
                end
                pp = 1;
                for p = 1:plt
                    figure
                    set(gcf,'Position',[19 343 1200 350])
    %                  for sp = 1:sbp
                        subplot(sbp,1,1)
                        bb = [];
                        for e = 1:length(eye)

                            indxt = pp*nsamplesPerPlot*sFc-nsamplesPerPlot*sFc+1:pp*nsamplesPerPlot*sFc;
                            t     = [pp*nsamplesPerPlot-nsamplesPerPlot+1:1/sFc:pp*nsamplesPerPlot]/1000;
                            if indxt(end)>length(trial(tr).(eyes{eye(e)}).samples.x)
                                indxt = indxt(1):length(trial(tr).(eyes{eye(e)}).samples.x);
                                t     = pp*nsamplesPerPlot-nsamplesPerPlot+1:1/sFc:pp*nsamplesPerPlot-nsamplesPerPlot+1+1/sFc*length(indxt)-1;
                            end
                            if corbsl==1
                             bsl = 0;
                                else
                            bsl = movavg(trial(tr).(eyes{eye(e)}).samples.x(indxt),250,250,1); 
                            end

                            plot(t,trial(tr).(eyes{eye(e)}).samples.x(indxt)-bsl','Color',colors(eye(e),:)), hold on
                           bb = [bb,trial(tr).(eyes{eye(e)}).samples.x(indxt)-bsl'];
                        end
                        if corbsl==1
                            pl = prctile(bb(~isnan(bb)),[1 99]);
                        else
                            pl = prctile(bb(~isnan(bb)),[2.5 97.5]);
                        end
                        if any(pl)
                         ylim([pl(1) 1.1*pl(2)])

                         text([pp*nsamplesPerPlot-nsamplesPerPlot+1+nsamplesPerPlot*.02]/1000,pl(2),'Horizontal Pos','Fontsize',12)
                         text([pp*nsamplesPerPlot-nsamplesPerPlot+1+nsamplesPerPlot*.9]/1000,pl(2),titlelabels(tr),'Fontsize',12,'Color',colors(eye(e),:))
                        end
                         box off
    %                     set(gca,'XTickLabels',{})

                        subplot(sbp,1,2)
                        bb = [];
                        for e = 1:length(eye)
                            indxt = pp*nsamplesPerPlot*sFc-nsamplesPerPlot*sFc+1:pp*nsamplesPerPlot*sFc;
                            t     = [pp*nsamplesPerPlot-nsamplesPerPlot+1:1/sFc:pp*nsamplesPerPlot]/1000;
                            if indxt(end)>length(trial(tr).(eyes{eye(e)}).samples.x)
                                indxt = indxt(1):length(trial(tr).(eyes{eye(e)}).samples.y);
                                t     = pp*nsamplesPerPlot-nsamplesPerPlot+1:1/sFc:pp*nsamplesPerPlot-nsamplesPerPlot+1+1/sFc*length(indxt)-1;
                            end
                            plot(t,trial(tr).(eyes{eye(e)}).samples.y(indxt),'Color',colors(eye(e),:)), hold on
                         bb = [bb,trial(tr).(eyes{eye(e)}).samples.y(indxt)];

                        end
                         if any(pl)
                        pl = prctile(bb(~isnan(bb)),[1 99]);
                         ylim([pl(1) 1.1*pl(2)])
                          text([pp*nsamplesPerPlot-nsamplesPerPlot+1+nsamplesPerPlot*.02]/1000,pl(2),'Vertical Pos','Fontsize',12)
                        text([pp*nsamplesPerPlot-nsamplesPerPlot+1+nsamplesPerPlot*.9]/1000,pl(2),titlelabels(tr),'Fontsize',12,'Color',colors(eye(e),:))
                         end
                           box off
    %                     set(gca,'XTickLabels',{})

                        subplot(sbp,1,3)
                        for e = 1:length(eye)
                            indxt = pp*nsamplesPerPlot*sFc-nsamplesPerPlot*sFc+1:pp*nsamplesPerPlot*sFc;
                            t     = [pp*nsamplesPerPlot-nsamplesPerPlot+1:1/sFc:pp*nsamplesPerPlot]/1000;
                            if indxt(end)>length(trial(tr).(eyes{eye(e)}).samples.x)
                                indxt = indxt(1):length(trial(tr).(eyes{eye(e)}).samples.xvel);
                                t     = pp*nsamplesPerPlot-nsamplesPerPlot+1:1/sFc:pp*nsamplesPerPlot-nsamplesPerPlot+1+1/sFc*length(indxt)-1;
                            end
                            plot(t,trial(tr).(eyes{eye(e)}).samples.xvel(indxt),'k'), hold on
                        end
                        box off
                        ylim([-300 300])
                         text([pp*nsamplesPerPlot-nsamplesPerPlot+1+nsamplesPerPlot*.02]/1000,300*.9,'Velocity','Fontsize',12)
                        text([pp*nsamplesPerPlot-nsamplesPerPlot+1+nsamplesPerPlot*.9]/1000,300*.9,titlelabels(tr),'Fontsize',12,'Color',colors(eye(e),:))

                        pp = pp+1;
    %                 end
                    set(gcf,'name',titlelabels{tr})
                    tightfig
                    set(gcf,'Position',[19 343 1200 350])

                    set(gcf, 'PaperPositionMode', 'auto')
                    if tr==1 & corbsl==1
                        export_fig([PATHSTR, filesep, fignames],'-pdf','-transparent')
                    else
                        export_fig([PATHSTR, filesep, fignames],'-pdf','-transparent','-append')
                    end
                end
            end
        end
end


