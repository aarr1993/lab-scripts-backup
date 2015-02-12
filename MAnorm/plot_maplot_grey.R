png(file="dripc_drip_maplot_onlygrey.png", width=960, height=768)

# most significant to least significant
col6 = "gray20" 
col5 = "gray30"
col4 = "gray40"
col3 = "gray50"
col2 = "gray60"
col1 = "gray80"

colors <- c(col1, col2, col3, col4, col5, col6)

data<-read.delim("/data/aparna/trans_targets/onlygrey_marked_out.xls", header=FALSE)

x<-c(-10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10)

plot(data$V8, data$V7, pch=20, xlim=c(0,20), yaxt="n", main="DRIPc vs DRIP read density", ylab="M: log2(DRIPc/DRIP)", xlab="A: 0.5 x log2(DRIPc/DRIP)", cex=0.5, col=ifelse(
  data$V12 == "0", col1, ifelse(
    data$V12 == "1", col2, ifelse(
      data$V12 == "2", col3, ifelse(
        data$V12 == "3", col4, ifelse(
          data$V12 == "4", col5, col6
        )
      )
    )
  )
))

axis(2, at=x,labels=x, col.axis="black", las=2)

dev.off()


