pdf("dripc_drip_replication_maplot.pdf")

# most significant to least significant
col6 = "gray20" 
col5 = "gray30"
col4 = "gray40"
col3 = "gray50"
col2 = "gray60"
col1 = "gray80"
colm = "blue"
coln = "red"
colnm = "purple"

colors <- c(col1, col2, col3, col4, col5, col6)
colors2 <- c(coln, colm, colnm)

data<-read.delim("/data/aparna/trans_targets/sorted_MAnorm_outfile_pvalscript_replication.xls", header=FALSE)
#attach(data)

x<-c(-10, -8, -6, -4, -2, 0, 2, 4, 6, 8, 10)

plot(data$V8, data$V7, pch=20, xlim=c(0,20), yaxt="n", main="DRIPc vs DRIP read density", ylab="M: log2(DRIPc/DRIP)", xlab="A: 0.5 x log2(DRIPc/DRIP)", cex=0.5, col=ifelse(
  data$V12 == "0", col1, ifelse(
    data$V12 == "1", col2, ifelse(
      data$V12 == "2", col3, ifelse(
        data$V12 == "3", col4, ifelse(
          data$V12 == "4", col5, ifelse(
            data$V12 == "5", col6, ifelse(
              data$V12 == "n", coln, ifelse(
                data$V12 == "z", colm, colnm 
              )
            )
          )
        )
      )
    )
  )
))

axis(2, at=x,labels=x, col.axis="black", las=2)

legend("bottomright", title="-log10(p-values)", c("not significant", "5 < p < 10", "10 < p < 50", "50 < p < 150", "150 < p < 300", "p > 300"), fill=colors, horiz=FALSE)
legend("topright", title="Overlap with", c("NEAT1 targets", "MALAT1 targets", "NEAT1/MALAT1 co-targets"), fill=colors2, horiz=FALSE)

abline(h=0, lty=2, lwd=2)

dev.off()


