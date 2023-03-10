
  replicationTabReserve<-tabPanel("Replicate",
         style = paste("background: ",subpanelcolours$designC), 
         wellPanel(
           style = paste("background: ",subpanelcolours$designC,";"),
           tags$table(width = "100%",class="myTable",
                      tags$tr(
                        tags$td(width = "25%", tags$div(style = localStyle, "Replication:")),
                        tags$td(width = "5%", 
                                checkboxInput("sReplicationOn",label=NULL,value=design$sReplicationOn)
                        ),
                        tags$td(width="70%")
                      )
           ),
           tags$table(width = "100%",class="myTable",
                      tags$tr(
                        tags$td(width = "20%", tags$div(style = localStyle, "Power:")),
                        tags$td(width = "15%", 
                                numericInput("sReplPower",label=NULL,value=design$sReplPower,min=0, max=1, step=0.1)
                        ),
                        tags$td(width = "30%", tags$div(style = localStyle, "Adjust")),
                        tags$td(width = "5%", 
                                checkboxInput("sReplCorrection",label=NULL,value=design$sReplCorrection)
                        ),
                        tags$td(width = "30%", selectInput("sReplTails",label=NULL,
                                                           choices=c("2-tail"=2,"1-tail"=1),
                                                           selected=design$sReplTails,selectize=FALSE))
                      ),
                      tags$tr(
                        tags$td(width = "20%", tags$div(style = localStyle, "No Reps:")),
                        tags$td(width = "15%", 
                                numericInput("sReplRepeats",label=NULL,value=design$sReplRepeats,min=1, max=10, step=1)
                        ),
                        tags$td(width = "30%", tags$div(style = localStyle, "Sig Original:")),
                        tags$td(width = "5%", 
                                checkboxInput("sReplSigOnly",label=NULL,value=design$sReplSigOnly)
                        ),
                        tags$td(width = "30%", 
                                selectInput("sReplKeep",label=NULL,
                                            choices=c("last","largest","joint"),
                                            selected=design$sReplKeep,selectize=FALSE)
                        ),
                      )
           )
         )
)
  
  if (switches$doReplications){
    replicationTab<-replicationTabReserve
  } else {
    replicationTab<-c()
  }
  