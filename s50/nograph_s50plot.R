args<-commandArgs(trailingOnly=TRUE)
filename<-args[1]
print(filename)
file<-read.delim(filename, header=F)
file<-na.omit(file) 
x<-file$V1
y<-file$V2
smspl<-smooth.spline(x,y)
d2<-function(x) predict(smspl,x,deriv=2)$y
out<-predict(smspl,x,deriv=0)
infl<-c(FALSE, diff(diff(out$y)>0)!=0)
critptsx<-out$x[infl ]
inflpts=NULL
for (i in 2:length(critptsx)) {
    error<-try(uniroot(f=d2, interval=c(critptsx[i], critptsx[i-1])))
    if (inherits(error, "try-error")) {
      next 
    }
    else {
      pt<-uniroot(f=d2, interval=c(critptsx[i], critptsx[i-1]))
      inflpts[i-1]<-pt$root
    }
}
infl2<-c(FALSE, diff(diff(out$y)>0)<0)
maxes<-out$x[infl2 ]
maxesy<-out$y[infl2 ]
infl3<-c(FALSE, diff(diff(out$y)>0)>0)
mins<-out$x[infl3 ]
minsy<-out$y[infl3 ]
early=NULL
late=NULL
inflpts<-na.omit(inflpts)
for (n in 2:length(inflpts)) {
# here identify early and late origins using the max and min arrays
  for (j in 1:length(maxes)) {
    if (maxes[j] > inflpts[n]) {
      break
    }
    else if (maxes[j] > inflpts[n - 1] && maxesy[j] > 70) { # threshold
      late[length(late)+1] <- inflpts[n - 1] 
      late[length(late)+1] <- inflpts[n] 
    }
  }
  for (k in 1:length(mins)) {
    if (mins[k] > inflpts[n]) {
      break
    }
    else if (mins[k] > inflpts[n - 1] && minsy[k] < 30) { # threshold
      early[length(early)+1] <- inflpts[n - 1] 
      early[length(early)+1] <- inflpts[n] 
    }
  }
}
#cat("EARLY")
 
#print(early)

#cat("LATE")

#print(late)

sink("earlyorigins.txt")
for (m in 1:length(early)) {
  cat(early[m])
  cat("\t")
  if (m %% 2 == 0) {
    cat("\n")
  }
}
sink()

sink("lateorigins.txt") 
for (o in 1:length(late)) {
  cat(late[o])
  cat("\t")
  if (o %% 2 == 0) {
    cat("\n")
  }
}
sink()

print("OUTFILES: earlyorigins.txt lateorigins.txt")

#earlyfile<-read.delim("earlyorigins.txt", header=F)
#earlyx0<-earlyfile$V1
#earlyx1<-earlyfile$V2
#height<-rep(30, times=length(earlyx0))

#latefile<-read.delim("lateorigins.txt", header=F)
#latex0<-latefile$V1
#latex1<-latefile$V2
#height<-rep(70, length(latex0))
