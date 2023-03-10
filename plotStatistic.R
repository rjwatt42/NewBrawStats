min_p=0.0001
truncate_p=TRUE
max_s=6
min_nw=10
max_nw=10000
horiz_scatter=0.5

se_colour="#BBBBBB"
se_size=0.75
se_arrow=0.3
CI=0.95

histGain<-NA

collectData<-function(result) {
  ns<-cbind(result$nval)
  rp<-cbind(result$rpIV)
  ro<-cbind(result$roIV)
  po<-cbind(result$poIV)

  if (all(is.na(result$rIV2))){
    rs<-cbind(result$rIV)
    ps<-cbind(result$pIV)
  } else {
    switch (result$showType,
            "direct"={
              rs<-rbind(result$r$direct)
              ps<-rbind(result$p$direct)
            },
            "unique"={
              rs<-rbind(result$r$unique)
              ps<-rbind(result$p$unique)
            },
            "total"={
              rs<-rbind(result$r$total)
              ps<-rbind(result$p$total)
            },
            "all"={
              rs<-c()
              ps<-c()
              ysc=1/3
              xoff=c(0,0,0,2,2,2,4,4,4)
              for (jk in 1:ncol(result$r$direct)) {
                rs<-cbind(rs,result$r$direct[,jk],result$r$unique[,jk],result$r$total[,jk])
                ps<-cbind(ps,result$p$direct[,jk],result$p$unique[,jk],result$p$total[,jk])
              }
            },
            "coefficients"={
              rs<-rbind(result$r$coefficients)
              ps<-rbind(result$p$direct)
            }
    )
  }
  if (truncate_p) {
    ps[ps<min_p]<-min_p
    po[po<min_p]<-min_p
  }
  out<-list(rs=rs,ps=ps,ns=ns,rp=rp,ro=ro,po=po)
}

makeFiddle<-function(y,yd){
  yz<-c()
  xz<-c()
  xd<-0.15
  
  for (i in 1:length(y)){
    found<-(abs(yz-y[i])<yd)
    if (any(found,na.rm=TRUE)) {
      x_max<-max(xz[found])
      x_which<-which.max(xz[found])
      y_at_max<-yz[found][x_which]
      x_min<-min(xz[found])
      x_which<-which.min(xz[found])
      y_at_min<-yz[found][x_which]
      if (abs(x_min)<x_max) {
        x_inc<-sqrt(1-((y[i]-y_at_min)/yd)^2)
        xz<-c(xz,x_min-x_inc*xd)
        yz<-c(yz,y[i])
      } else {
      x_inc<-sqrt(1-((y[i]-y_at_max)/yd)^2)
      xz<-c(xz,x_max+x_inc*xd)
      yz<-c(yz,y[i])
      }
    } else {
      xz<-c(xz,0)
      yz<-c(yz,y[i])
    }
  }
  
  return(xz)
}

get_upperEdge<-function(nsvals,vals){
  target1<-max(nsvals,na.rm=TRUE)
  if (any(vals>target1,na.rm=TRUE)){
    target2<-min(vals[vals>target1],na.rm=TRUE)
    target<-(target1+target2)/2
  } else target<-target1+0.001
}
get_lowerEdge<-function(nsvals,vals) {
  target1<-min(nsvals,na.rm=TRUE)
  if (any(vals<target1)){
    target2<-max(vals[vals<target1],na.rm=TRUE)
    if (target2==-Inf) target2=target1-0.5
    target<-(target1+target2)/2
  } else {target<-target1-0.5}
}

getBins<-function(vals,nsvals,target,minVal,maxVal,fixed=FALSE) {
  nv=max(length(nsvals),length(vals))
  nb<-round(sqrt(nv)*0.75)
  if (min(vals,na.rm=TRUE)==max(vals,na.rm=TRUE)) {nb<-3}
  # nb<-51
  
  high_p<-max(vals,na.rm=TRUE)+0.2
  low_p<-min(vals,na.rm=TRUE)-0.2
  if (!is.null(minVal)) {
    low_p<-min(max(minVal-0.2,low_p,na.rm=TRUE),target)
  }
  if (!is.null(maxVal)) {
    high_p<-min(maxVal+0.2,high_p,na.rm=TRUE)
  }
  if ((length(nsvals)==0) || (length(nsvals)==length(vals))){
    bins<-seq(low_p,high_p,length.out=nb)
  } else {
    if (fixed) {
      target_low<-max(-target,low_p)
      target_high<-min(target,high_p)
      targetRange<-target_high-target_low
      nbs<-ceiling(nb*targetRange/(high_p-low_p))
      binStep<-targetRange/nbs
      bins<-seq(target_low,target_high,binStep)
      if (target<high_p) {
        bins<-c(bins,seq(target+binStep,high_p+binStep,binStep))
      }
      if (-target>low_p) {                                
        bins<-c(rev(seq(-target-binStep,low_p-binStep,-binStep)),bins)
      }
    } else {
    nbs<-ceiling(nb*(high_p-target)/(high_p-low_p))
    binStep<-(high_p-target)/nbs
    bins<-rev(seq(high_p,low_p-binStep,-binStep))
    }
  }
  bins
}

expected_hist<-function(vals,nsvals,valType){

  if (is.element(valType,c("r1","rp","ci1","ci2"))) valType<-"r"
  if (is.element(valType,c("e1","e2","p1"))) valType<-"p"
  if (is.element(valType,c("wp"))) valType<-"w"
  
  switch (valType,
          "r"=  { # ns is small
            target<-get_upperEdge(abs(nsvals),abs(vals))
            bins<-getBins(vals,nsvals,target,NULL,NULL,TRUE)
          },
          
          "p"=  { # ns is large
            target<-log10(alpha)
            bins<-getBins(vals,nsvals,target,log10(min_p),NULL)
          },
            
          "log(lrs)"={
            target<-3
            bins<-getBins(vals,nsvals,target,0,5)
          },
          
          "log(lrd)"={
            target<-3
            bins<-getBins(vals,nsvals,target,0,5)
          },
          
          "w"=  { # ns is small
            target<-get_upperEdge(abs(nsvals),abs(vals))
            bins<-getBins(vals,nsvals,target,log10(min_p),NULL)
          },
          
          "n"= { # ns is small
            target<-get_lowerEdge(nsvals,vals)
            bins<-getBins(vals,nsvals,target,NULL,10000,FALSE)
          },
          
          "nw"= { # ns is large
            target<-get_lowerEdge(nsvals,vals)
            bins<-getBins(vals,nsvals,target,NULL,max_nw,FALSE)
          }
  )
  useBins<-c(-Inf,bins,Inf)
  dens<-hist(vals,breaks=useBins,plot=FALSE,warn.unused = FALSE,right=TRUE)
  dens<-dens$counts
  dens<-dens[2:(length(dens)-1)]

  nsdens<-hist(nsvals,breaks=useBins,plot=FALSE,warn.unused = FALSE,right=TRUE)
  nsdens<-nsdens$counts
  nsdens<-nsdens[2:(length(nsdens)-1)]

  if (is.na(histGain)) {
    nsdens<-nsdens/max(dens,na.rm=TRUE)/2
    dens<-dens/max(dens,na.rm=TRUE)/2
  } else {
    nsdens<-nsdens/(sum(dens)*(bins[2]-bins[1]))*histGain
    dens<-dens/(sum(dens)*(bins[2]-bins[1]))*histGain
  }
  
  x<-as.vector(matrix(c(bins,bins),2,byrow=TRUE))
  y1<-c(0,as.vector(matrix(c(dens,dens),2,byrow=TRUE)),0)
  y2<-c(0,as.vector(matrix(c(nsdens,nsdens),2,byrow=TRUE)),0)
  data.frame(y1=c(-y1,rev(y1)), y2=c(-y2,rev(y2)), x=c(x,rev(x)))
}

start_plot<-function() {
  g<-ggplot()
  g<-g+theme(legend.position = "none")+plotTheme
  g<-g+scale_x_continuous(breaks=NULL)
  g+theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank())
}

expected_plot<-function(g,pts,result,IV,DV,expType,single=FALSE){
  if (useSignificanceCols){
    c1=plotcolours$infer_sigC
    c2=plotcolours$infer_nsigC
  } else {
    c1=plotcolours$descriptionC
    c2=plotcolours$descriptionC
  }
  if (expType=="e1") {
    c1=plotcolours$infer_err
    c2=plotcolours$infer_nsigC
  }
  if (expType=="e2") {
    c1=plotcolours$infer_sigC
    c2=plotcolours$infer_err
  }
  dotSize<-(plotTheme$axis.title$size)/3
  
  if (single) {
    xr<-makeFiddle(pts$y1,2/40)
    
    if (expType=="r" && length(pts$y1)==1 && !is.null(result$rCI)){
      pts1se<-data.frame(x=pts$x,y=result$rCI)
      if (isSignificant(STMethod,result$pIV,result$rIV,result$nval,result$evidence)) {c<-c1} else (c<-c2)
      g<-g+geom_line(data=pts1se,aes(x=x,y=y),arrow=arrow(length=unit(se_arrow,"cm"),ends="both"),colour=c,size=se_size)
    }
    if (expType=="p" && length(pts$y1)==1 && !is.null(result$pCI)){
      pts1se<-data.frame(x=pts$x,y=log10(result$pCI))
      if (isSignificant(STMethod,result$pIV,result$rIV,result$nval,result$evidence)) {c<-c1} else (c<-c2)
      g<-g+geom_line(data=pts1se,aes(x=x,y=y),arrow=arrow(length=unit(se_arrow,"cm"),ends="both"),colour=c,size=se_size)
    }
    
    pts$x<-pts$x+xr
    pts1=pts[pts$y2,]
    g<-g+geom_point(data=pts1,aes(x=x, y=y1),shape=shapes$study, colour = "black", fill = c2, size = dotSize)
    pts2=pts[!pts$y2,]
    g<-g+geom_point(data=pts2,aes(x=x, y=y1),shape=shapes$study, colour = "black", fill = c1, size = dotSize)
    
  } else {
    if (is.logical(pts$y2)) {
      pts1<-expected_hist(pts$y1,pts$y1[pts$y2],expType)
    } else {
      pts1<-expected_hist(pts$y1,pts$y2,expType)
    }
    xoff<-pts$x[1]
    g<-g+
      geom_polygon(data=pts1,aes(y=x,x=y1+xoff),colour=NA, fill = c1)+
      geom_polygon(data=pts1,aes(y=x,x=y2+xoff),colour=NA, fill = c2)
  }
  g
}


r_plot<-function(result,IV,IV2=NULL,DV,effect,expType="r",logScale=FALSE){
  r<-effect$rIV
  if (!is.null(IV2)){
    r<-c(r,effect$rIV2,effect$rIVIV2DV)
  }
  
  rActual<-r
  rActual[is.na(r)]<-0

  single<-TRUE
  if (length(result$rIV)>points_threshold) {single<-FALSE}
  
  if (all(is.na(result$rIVIV2DV)) && is.null(IV2)){
    xoff=0
  } else {
    if (is.na(result$rIVIV2DV[1])){
      xoff=c(0,2)
    } else {
      xoff=c(0,2,4)
    }
  }
  
  switch (expType,
          "r"={
            ylim<-c(-1, 1)
            ylabel<-"r"
            },
          "p"={
            ylim<-c(min_p, 1)
            ylabel<-bquote(p)
          },
          "p1"={
            ylim<-c(min_p, 1)
            ylabel<-bquote(p[1])
          },
          "log(lrs)"={
            ylim<-c(0, max_s)
            ylabel<-bquote(log[e](lr[s]))
          },
          "log(lrd)"={
            ylim<-c(0, max_s)
            ylabel<-bquote(log[e](lr[d]))
          },
          "w"={
            ylim<-c(0.01, 1)
            ylabel<-bquote(w)
          },
          "nw"={
            ylim<-c(1, max_nw)
            ylabel<-bquote(n[w=80])
            },
          "n"={
            ylim<-c(1, result$design$sN*5*1.1)
            ylabel<-"n"
          },
          "rp"={
            ylim<-c(-1, 1)
            ylabel<-"R"
          },
          "r1"={
            ylim<-c(-1, 1)
            ylabel<-bquote(r[1])
          },
          "wp"={
            ylim<-c(0.01, 1)
            ylabel<-bquote(w)
          },
          "ci1"={
            ylim<-c(-1,1)
            ylabel<-"r"
          },
          "ci2"={
            ylim<-c(-1,1)
            ylabel<-"r"
          },
          "e1"={
            ylim<-c(min_p, 1)
            ylabel<-bquote(p)
          },
          "e2"={
            ylim<-c(min_p, 1)
            ylabel<-bquote(p)
          }
  )
  if (logScale) {
    ylim<-log10(ylim)
    ylabel<-bquote(log[10](.(ylabel)))
  }  
  
  if (!all(is.na(result$rIV))) {
    data<-collectData(result)
    switch (expType,
            "r"={data$sh<-data$rs},
            "rp"={data$sh<-data$rp},
            "r1"={data$sh<-data$ro},
            "p"={data$sh<-data$ps},
            "p1"={data$sh<-data$po},
            "log(lrs)"={data$sh<-res2llr(result,"sLLR")},
            "log(lrd)"={data$sh<-res2llr(result,"dLLR")},
            "n"={data$sh<-data$ns},
            "w"={data$sh<-rn2w(data$rs,data$ns)},
            "wp"={data$sh<-rn2w(data$rp,data$ns)},
            "nw"={data$sh<-rw2n(data$rs,0.8,result$design$sReplTails)},
            "ci1"={data$sh<-r2ci(data$rs,data$ns,-1)},
            "ci2"={data$sh<-r2ci(data$rs,data$ns,+1)},
            "e1"={data$sh<-data$ps},
            "e2"={data$sh<-data$ps}
    )
    if (logScale) {
      data$sh<-log10(data$sh)
    }  
  }    
  g<-start_plot()
  
  # make theory
  for (i in 1:length(xoff)){
    if (result$evidence$showTheory) {
      if (is.element(expType,c("p","e1","e2","p1"))) {
        if (logScale) {
          yv<-seq(log10(min_p),0,length.out=51)
          yvUse<-10^yv
        }else{
          yv<-seq(0,1,length.out=51)
          yvUse<-yv
        }
        xd<-fullRSamplingDist(yvUse,result$effect$world,result$design,"p",logScale=logScale)
      } else {
        npt<-101
      switch(expType,
             "r"={
               yv<-seq(-1,1,length.out=npt)*0.99
               xd<-fullRSamplingDist(yv,result$effect$world,result$design,"r",logScale=logScale)
             },
             "r"={
               yv<-seq(-1,1,length.out=npt)*0.99
               xd<-fullRSamplingDist(yv,result$effect$world,result$design,"r",logScale=logScale)
             },
             "ci1"={
               yv<-seq(-1,1,length.out=npt)*0.99
               xd<-fullRSamplingDist(yv,result$effect$world,result$design,"r",logScale=logScale)
             },
             "ci2"={
               yv<-seq(-1,1,length.out=npt)*0.99
               xd<-fullRSamplingDist(yv,result$effect$world,result$design,"r",logScale=logScale)
             },
             "w"={
               yv<-seq(alpha*1.01,1/1.01,length.out=npt)
               xd<-fullRSamplingDist(yv,result$effect$world,result$design,"w",logScale=logScale)
             },
             "log(lrs)"={
               yv<-seq(0,max_s,length.out=npt)
               xd<-fullRSamplingDist(yv,result$effect$world,result$design,"log(lrs)",logScale=logScale)
             },
             "log(lrd)"={
               yv<-seq(0,max_s,length.out=npt)
               xd<-fullRSamplingDist(yv,result$effect$world,result$design,"log(lrd)",logScale=logScale)
             },
             "nw"={
               if (logScale) {
                 yv<-seq(log10(5),log10(max_nw),length.out=npt)
                 yvUse<-10^yv
               }else{
                 yv<-5+seq(0,max_nw,length.out=npt)
                 yvUse<-yv
               }
               xd<-fullRSamplingDist(yvUse,result$effect$world,result$design,"nw",logScale=logScale)
             },
             "rp"={
               yv<-seq(-1,1,length.out=npt)*0.99
               xd<-fullRPopulationDist(yv,result$effect$world)
             },
             "n"={
               if (logScale) {
                 yv<-seq(log10(5),log10(5*result$design$sN),length.out=npt)
                 yvUse<-yv^10
               }else{
                 yv<-5+seq(0,5*result$design$sN,length.out=npt)
                 yvUse<-yv
               }
               xd<-getNDist(yv,result$design,logScale=logScale)
             },
             "wp"={
               yv<-seq(alpha*1.01,1/1.01,length.out=npt)
               xd<-fullRSamplingDist(yv,result$effect$world,result$design,"wp",logScale=logScale)
             }
      )
      }
      xd[is.na(xd)]<-0
        xd<-xd/max(xd)/2
      histGain<<-sum(xd)*(yv[2]-yv[1])
      ptsp<-data.frame(y=c(yv,rev(yv)),x=c(xd,-rev(xd))+xoff[i])
      g<-g+geom_polygon(data=ptsp,aes(x=x,y=y),colour="black",fill="white")
    } else {
      histGain<-NA
    }

    # then the samples
  if (!all(is.na(result$rIV))) {
      shvals<-data$sh[,i]
      rvals<-data$rs[,i]
      pvals<-data$ps[,i]
      resSig<-isSignificant(STMethod,pvals,rvals,data$ns,result$evidence)
      if (result$showType=="all") {
        ysc<-1/3
        rvals<-(rvals+1)*ysc*0.9+rem(i-1,3)*ysc*2-1
      }
      pts<-data.frame(x=rvals*0+xoff[i],y1=shvals,y2=!resSig,n<-data$ns)
      g<-expected_plot(g,pts,result,IV,DV,expType,single)
    
    if (is.element(expType,c("p","e1","e2"))) {
      switch (expType,
              "p"={labelPt1<-"p(sig) = "},
              "e1"={labelPt1<-"p(Type I) = "},
              "e2"={labelPt1<-"p(Type II) = "}
      )
      if (expType=="e2") {
        labelPt2<-paste0(labelPt1,format(mean(!resSig,na.rm=TRUE),digits=graph_precision))
        labelPt3<-paste0(labelPt2,"  (",format(sum(!resSig,na.rm=TRUE)),"/",format(length(pvals)),")")
      } else {
        labelPt2<-paste0(labelPt1,format(mean(resSig,na.rm=TRUE),digits=graph_precision))
        labelPt3<-paste0(labelPt2,"  (",format(sum(resSig,na.rm=TRUE)),"/",format(length(pvals)),")")
      }
      if (length(xoff)>1) {
        lpts<-data.frame(x = xoff[i]-0.95, y = ylim[2],label = labelPt2)
      } else {
        lpts<-data.frame(x = xoff[i]-0.95, y = ylim[2],label = labelPt3)
      }
      g<-g+geom_label(data=lpts,aes(x = x, y = y, label=label), hjust=0, vjust=0, fill = "white",size=3)
    }
    
    if (is.element(expType,c("r","ci1","ci2"))) {
      lpts<-data.frame(x = xoff[i]-0.95, y = ylim[2],label=paste("actual =",format(rActual[i],digits=graph_precision)))
      g<-g+geom_label(data=lpts,aes(x = x, y = y, label = label), hjust=0, vjust=0, fill = "white",size=3)
    }
  }
  }
  
  if (length(xoff)>1)
    if (rem(i,3)==1)
      switch (xoff[i]/2+1,
              {g<-g+annotate("text",x=xoff[i],y=ylim[2]+diff(ylim)/16,label="Main Effect 1",color="white",size=3)},
              {g<-g+annotate("text",x=xoff[i],y=ylim[2]+diff(ylim)/16,label="Main Effect 2",color="white",size=3)},
              {g<-g+annotate("text",x=xoff[i],y=ylim[2]+diff(ylim)/16,label="Interaction",color="white",size=3)}
      )

  if (result$showType=="all") {
    for (i in 1:3) {
      g<-g+geom_hline(yintercept=(-1+1)*ysc*0.9+(i-1)*ysc*2-1, color="black", size=1)
      g<-g+geom_hline(yintercept=(0.0+1)*ysc*0.9+(i-1)*ysc*2-1, linetype="dotted", color="black", size=0.5)
      g<-g+geom_hline(yintercept=(1+1)*ysc*0.9+(i-1)*ysc*2-1, color="black", size=1)
    }
    g<-g+coord_cartesian(xlim = c(min(xoff),max(xoff))+c(-1,1), ylim = ylim+c(0,diff(ylim)/16))+
      scale_y_continuous(breaks=(c(-1,0,1,-1,0,1,-1,0,1)+1)*ysc*0.9+(c(1,1,1,2,2,2,3,3,3)-1)*ysc*2-1,labels=c(-1,0,1,-1,0,1,-1,0,1))
  } else {
    g<-g+geom_hline(yintercept=0.0, linetype="dotted", color="black", size=0.5)+
      coord_cartesian(xlim = c(min(xoff),max(xoff))+c(-1,1), ylim = ylim+c(0,diff(ylim)/16))
  }
  g<-g+ylab(ylabel)
  g
}


r1_plot<-function(result,IV,IV2=NULL,DV,effect){
  r_plot(result,IV,IV2,DV,effect,"r1")
}

rp_plot<-function(result,IV,IV2=NULL,DV,effect){
  r_plot(result,IV,IV2,DV,effect,"rp")
}

llrs_plot<-function(result,IV,IV2=NULL,DV,effect){
  g<-r_plot(result,IV,IV2,DV,effect,"log(lrs)")
  sAlpha<-log(dnorm(0)/dnorm(qnorm(1-alpha/2)))
  g<-g+geom_hline(yintercept=sAlpha, linetype="dotted", color="#44FF22", size=0.5)
  g
}

llrd_plot<-function(result,IV,IV2=NULL,DV,effect){
  g<-r_plot(result,IV,IV2,DV,effect,"log(lrd)")
  sAlpha<-log(dnorm(0)/dnorm(qnorm(1-alpha/2)))
  g<-g+geom_hline(yintercept=sAlpha, linetype="dotted", color="#44FF22", size=0.5)
  g
}

p_plot<-function(result,IV,IV2=NULL,DV,effect,ptype="p"){

  g<-r_plot(result,IV,IV2,DV,effect,ptype,pPlotScale=="log10")
  
  if (pPlotScale=="log10") {
    g<-g+geom_hline(yintercept=log10(1), linetype="dotted", color="#FF4422", size=0.5)+
      geom_hline(yintercept=log10(0.005), linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=log10(0.01), linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=log10(alpha), linetype="dotted", color="#44FF22", size=0.5)+
      scale_y_continuous(breaks=c(-4,-3,-2,-1,0),labels=c(0.0001,0.001,0.01,0.1,1))
  } else
  {
    g<-g+geom_hline(yintercept=log10(alpha), linetype="dotted", color="#44FF22", size=0.5)+
      scale_y_continuous(breaks=seq(0,1,0.1),labels=seq(0,1,0.1))
  }
  g
}

p1_plot<-function(result,IV,IV2=NULL,DV,effect,ptype="p1"){
  g<-r_plot(result,IV,IV2,DV,effect,ptype,pPlotScale=="log10")
  
  if (pPlotScale=="log10") {
    g<-g+geom_hline(yintercept=log10(1), linetype="dotted", color="#FF4422", size=0.5)+
      geom_hline(yintercept=log10(0.005), linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=log10(0.01), linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=log10(alpha), linetype="dotted", color="#44FF22", size=0.5)+
      scale_y_continuous(breaks=c(-4,-3,-2,-1,0),labels=c(0.0001,0.001,0.01,0.1,1))
  } else
  {
    g<-g+geom_hline(yintercept=log10(alpha), linetype="dotted", color="#44FF22", size=0.5)+
      scale_y_continuous(breaks=seq(0,1,0.1),labels=seq(0,1,0.1))
  }
  g
}


w_plot<-function(result,IV,IV2=NULL,DV,effect){
  g<-r_plot(result,IV,IV2,DV,effect,"w",wPlotScale=="log10")
  
  if (wPlotScale=="log10") {
    g<-g+geom_hline(yintercept=log10(alpha), linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=log10(0.5), linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=log10(0.8), linetype="dotted", color="#44FF22", size=0.5)
  } else {
    g<-g+geom_hline(yintercept=alpha, linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=0.5, linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=0.8, linetype="dotted", color="#44FF22", size=0.5)
  }
  g
}

wp_plot<-function(result,IV,IV2=NULL,DV,effect){
  g<-r_plot(result,IV,IV2,DV,effect,"wp",wPlotScale=="log10")
  
  if (wPlotScale=="log10") {
    g<-g+geom_hline(yintercept=log10(alpha), linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=log10(0.5), linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=log10(0.8), linetype="dotted", color="#44FF22", size=0.5)
  } else {
    g<-g+geom_hline(yintercept=alpha, linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=0.5, linetype="dotted", color="#44FF22", size=0.5)+
      geom_hline(yintercept=0.8, linetype="dotted", color="#44FF22", size=0.5)
  }
  g
}

n_plot<-function(result,IV,IV2=NULL,DV,effect){
  r_plot(result,IV,IV2,DV,effect,"n",nPlotScale=="log10")
}

nw_plot<-function(result,IV,IV2=NULL,DV,effect){
  r_plot(result,IV,IV2,DV,effect,"nw",nPlotScale=="log10")
}

e2_plot<-function(result,IV,IV2=NULL,DV,effect){
  p_plot(result,IV,IV2,DV,effect,ptype="e2")
}

e1_plot<-function(result,IV,IV2=NULL,DV,effect){
  p_plot(result,IV,IV2,DV,effect,ptype="e1")
}

ci1_plot<-function(result,IV=NULL,IV2=NULL,DV=NULL,effect){
  r_plot(result,IV,IV2,DV,effect,"ci1")
}

ci2_plot<-function(result,IV,IV2=NULL,DV,effect){
  r_plot(result,IV,IV2,DV,effect,"ci2")
}


