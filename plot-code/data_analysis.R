library(dplyr)
library(ggplot2)
library(zoo)

plot_style <- theme_bw() + theme(axis.text= element_text(size=18),
                                 axis.title = element_text(size=18))

pix_to_cm <- 1./4.7*0.1


##dir <- "E10-TURB-FLOW-US-DS-REV"
##dir <- "E3-STAT-US-DS"
##dir <- "E4_US-DS_REV"
##dir <- "E5-STAT-CW-CCW--DLC"
dir <- "E6-CW-CCW-REV--DLC"
data_files <- Sys.glob(paste(dir,'/*.dat',sep=""))

outdir_single_plots <- file.path(dir,"plots","single_fish/")
if (!dir.exists(outdir_single_plots)) { dir.create(outdir_single_plots,recursive=TRUE) }

##data_files <- Sys.glob('E3-STAT-US-DS/f1-static-us-vid_2018-08-15_17-57-59.mp4.dat')

## MAIN DATAFRAME

df <- data.frame()
for (f in data_files){

    con <- file(f, "r", blocking = FALSE)
    strgs <- readLines(con,n=1) 
    
    strgs = strsplit(strgs,' ')[[1]]
    stim_start= as.integer(strgs[2])
    exp_number = strgs[3]
    stim_type = strgs[4]
    fishID = strgs[5]
    trial_num = as.integer(strgs[6])

    df_exp <- read.table(con)

    ##remove first points
    df_exp <- df_exp[-c(1:5),]


    if (stim_type=="CCW" & trial_num == 2 & fishID == "F2") next

    
    print(f)
    
    colnames(df_exp) <- c("frame","xh","yh","xt","yt")
    df_exp$frame <- df_exp$frame - df_exp$frame[1] - stim_start
    df_exp$xh <- (2000 - df_exp$xh)*pix_to_cm
    df_exp$xt <- (2000 - df_exp$xt)*pix_to_cm
    df_exp$yh <- df_exp$yh*pix_to_cm
    df_exp$yt <- df_exp$yt*pix_to_cm
    

    ##xh_normalized <- ( df_exp$xh - min(df_exp$xh) )/avg_fish_length
#    print(f)
    #df_exp$xh <- df_exp$xh - df_exp[df_exp$frame== 0,]$xh + 500
    
    close(con)

    df <- rbind.data.frame(df,cbind.data.frame(df_exp,
                                               #xh_normalized=xh_normalized,
                                               exp_number,
                                               fishID,
                                               trial_num,
                                               stim_type,
                                               stim_start,
                                               filename=f))
    
}



prm1 <- ggplot(df,aes(x=frame,y=yh,colour=as.factor(filename))) + geom_point() + facet_grid(.~stim_type)




####
#### clean df and add quantities
####


tail_angle <- function(x){

    e = c(1,0)
    
    x = x / sqrt(sum(x**2))
    
    cos = x %*% e
    
    return(cos)
    
    
}

df.cleaned <- data.frame()
for (st in levels(df$stim_type) ){ ##stimulus type

    for ( ft in levels(df$fishID) ){ ## fish

        for (tr in levels(as.factor(df$trial_num))) {

            df_tmp <- filter(df,
                             ##xh<40 &
                             yh>7.5 & yh<13.5 &
                             stim_type == st  &
                             fishID == ft &
                             frame < 2000 & frame>-1000 & 
                             ##frame < 2500 & frame>-1500 & 
                             trial_num == tr)

            
            
            df_tmp <- mutate(df_tmp,
                             ##xh_ma = rollmean(xh,k=355,fill=NA), 
                             ##yt_ma = rollmean(yt-yh,k=45,fill=NA),
                             yh_ma = rollmean(yh,k=80,fill=NA),
                             ##tail_angle = apply(cbind(df_tmp$xt-df_tmp$xh,df_tmp$yt-df_tmp$yh),
                             ##1,FUN=tail_angle)
                             )

            df.cleaned <- rbind.data.frame(df.cleaned,df_tmp)
        }
    }
}


prm <- ggplot(df.cleaned,aes(x=frame,y=yh_ma,colour=as.factor(filename))) + geom_line() + facet_grid(.~stim_type)




####
####>>>>>>>>> SINGLE FISH
####



for (st in levels(df$stim_type) ){ ##stimulus type

    for ( ft in levels(df$fishID) ){ ## fish

        for (tr in levels(as.factor(df$trial_num))) {

            svg(paste(outdir_single_plots,st,"-",ft,"-",tr,"-",dir,".svg",sep=""))
            
            p=ggplot(filter(df.cleaned,
                            stim_type == st  &
                            fishID == ft &
                            trial_num == tr)) +
                
                geom_line(aes(x=frame,y=yh_ma),colour="orange") +
                
                geom_vline(xintercept = 0) +
                
                ##ylim(20,40) +
                
                ylim(7.5,13.5) +
    
                ylab("head (y coordinate) [cm]") + xlab("time [ms]") +
                
                ggtitle(paste("Fish:", ft, "- Stimulus type:", st, "- trial: ", tr,sep=" ")) + 
                
                plot_style
            
            print(p)
            
            dev.off()
            
        }
    }
}





## pdf(paste("single_fish_tail_oscillation-",dir,".pdf",sep=""))

## for (st in levels(df$stim_type) ){ ##stimulus type

##     for ( ft in levels(df$fishID) ){ ## fish

##         for (tr in levels(as.factor(df$trial_num))) {
            
##             p=ggplot(filter(df.cleaned,
##                             stim_type == st  &
##                             fishID == ft &
##                             trial_num == tr),
##                      aes(x=frame,y=yt_ma)) +
                
                
##                 geom_line(colour="orange",size=1) +
                
##                 geom_vline(xintercept = 0) + 
                
##                 ylab("tail position [cm]") + xlab("time [frame]") +
                
##                 ggtitle(paste("Fish:", ft, "- Stimulus type:", st, "- trial: ", tr, sep=" ")) + 
                
##                 plot_style
            
##             print(p)
            
##             }
##         }
##     }
## dev.off()





## ----- Average over fish and group for each stimulus

average.df <- data.frame()
for ( st in levels(as.factor(df$stim_type)) ) { ##for each stimulus
    
    d_merged <- zoo()
    for (f in levels(as.factor(df$fishID)) ) {

        for (r in levels(as.factor(df$trial_num)) ) {

            print(paste(st,f,r,sep=" "))
            
            df_F <- filter(df.cleaned,
                           stim_type == st  &
                           fishID == f &
                           trial_num == r)
            
            #d_merged <- merge(d_merged,zoo(order.by=df_F$frame,df_F$xh_ma))
            d_merged <- merge(d_merged,zoo(order.by=df_F$frame,df_F$yh_ma))
        }
    }

    
    average.df <- rbind.data.frame(average.df,
                                   cbind.data.frame(frame=-999:1999,### modify here if error. look the range in d_merged
                                                    xh=rowMeans(d_merged,na.rm=TRUE),
                                                    std_xh=as.numeric(apply(d_merged,1,function(x) sd(x,na.rm=TRUE))),
                                                    stim_type=st))

    
    
}

#average.df$xh[is.nan(average.df$xh)] <- NA


####
###>>>>>>>>>>>>>>>> GROUP average

for ( st in levels(as.factor(df$stim_type)) ){

    svg(paste(file.path(dir,"plots/"),"group-",dir,"-",st,".svg",sep=""))
    ##pdf(paste(file.path(dir,"plots/"),"group-",dir,"-",st,".pdf",sep=""))
    ##av.df <- select(filter(average.df,stim_type==st),frame,xh,std_xh)
    av.df <- select(filter(average.df,stim_type==st),frame,xh,std_xh)

    ## applico smoothing per la seconda volta per togliere step su curva group_average
    av.df$xh <- rollmean(av.df$xh,k=70,fill=NA)
    av.df$std_xh<- rollmean(av.df$std_xh,k=70,fill=NA)
    
    p <- ggplot(filter(df.cleaned,
                       stim_type == st,
                       frame<2000 & frame > -1000),
                aes(x=frame,y=yh_ma)) +
    
    geom_point(size=0.3,colour="gray",alpha=0.1) +

    geom_line(data=filter(av.df,
                          frame<2000 & frame > -1000),
              aes(x=frame,y=xh),
              colour="orange",
              size=2) +

    geom_line(data=filter(av.df,
                          frame<2000 & frame > -1000),
              aes(x=frame,y=xh-std_xh),
              colour="orange",
              linetype="dotted",
              size=2) +

    geom_line(data=filter(av.df,
                          frame<2000 & frame > -1000),
              aes(x=frame,y=xh+std_xh),
              colour="orange",
              linetype="dotted",
              size=2) +

    xlim(-1000,2000) +
    
    ## geom_ribbon(data=av.df,
    ##             aes(ymin=xh-std_xh, ymax=xh+std_xh),
    ##             alpha=0.3) +
    
    ggtitle(paste("Group average -- stim type:",st,sep=" ")) +
    
    geom_vline(xintercept = 0) +
    
    ylab("head position [cm]") + xlab("time [ms]") +

    plot_style
    
    print(p)

    dev.off()
}




























## ## ----- Average over fish and group for each stimulus
## ## normalized
## average.df <- data.frame()
## for ( st in levels(as.factor(df$stim_type)) ) { ##for each stimulus

##     d_merged <- zoo()
##     for (f in levels(as.factor(df$fishID)) ) {

##         for (r in levels(as.factor(df$trial_num)) ) {

##             print(paste(st,f,r,sep=" "))
            
##             df_F <- filter(df,
##                            xh_normalized<4 &
##                            stim_type == st  &
##                            fishID == f &
##                            frame < 2000 & frame>=-1000 &
##                            trial_num == r)
            
##             d_merged <- merge(d_merged,zoo(order.by=df_F$frame,df_F$xh_normalized))

##         }
##     }

##     average.df <- rbind.data.frame(average.df,
##                                    cbind.data.frame(frame=-1000:1999,
##                                                     xh_normalized=rowMeans(d_merged,na.rm=TRUE),
##                                                     std_xh_normalized=as.numeric(apply(d_merged,1,function(x) sd(x,na.rm=TRUE))),
##                                                     stim_type=st))    
## }


## ####
## ###>>>>>>>>>>>>>>>> GROUP average
## ### normalized


## pdf(paste("group-normalized",dir,".pdf",sep=""))

## for ( st in levels(as.factor(df$stim_type)) ){

##     av.df <- select(filter(average.df,stim_type==st),frame,xh_normalized,std_xh_normalized)
    
##     p <- ggplot(filter(df,
##                        xh_normalized<15 &
##                        stim_type == st &
##                        frame < 2000 & frame>-1000),
##                 aes(x=frame,y=xh_normalized)) +

##     geom_point(size=0.3,colour="gray",alpha=0.1) +

##     geom_ribbon(data=av.df,
##                 aes(ymin=(xh_normalized-std_xh_normalized),
##                     ymax=xh_normalized+std_xh_normalized),
##                  alpha=0.3) +

##     geom_line(data=av.df,
##               aes(x=frame,y=xh_normalized),
##               colour="orange",
##               size=2) +
    
##     ggtitle(paste("Group average -- stim type:",st,sep=" ")) +
    
##     geom_vline(xintercept = 0) +
    
##     ylab("(x - xmin)/fish_length [cm]") + xlab("time [ms]") +

##     ylim(-0.5,4) +
    
##     plot_style

##     print(p)
## }

## dev.off()



##geom_vline(aes(xintercept=stim_start,color=as.factor(rep)))
## df_ma <- mutate(df_filtered, ma = rollmean(xh,k=35,fill=NA))     

## ##df_ma %>% filter(frame>=-200 & frame <= 1000)

## p_ma <- ggplot(df_ma,aes(x=frame,y=ma,colour=as.factor(trial_num))) + geom_line(size=0.5) +
##      # scale_y_reverse() +
##      facet_grid(fishID~stim_type) + geom_vline(xintercept = 0) +
##      scale_colour_discrete(name="Trials") + coord_fixed(ratio=1) + ylab("x [pixels]") + xlab("time [frame]") + plot_style


