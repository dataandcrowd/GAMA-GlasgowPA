ENV["R_HOME"] = "C:\\Program Files\\R\\R-4.1.3" ## Windows
ENV["R_HOME"] = "/Library/Frameworks/R.framework/Resources" ##MacOSX

using Pkg
#Pkg.add("RCall") #<- Essential
#Pkg.build("RCall") #<- Essential
using RCall

#ggplot(diamonds, aes(x=carat, y=price)) + geom_point() +  theme_bw()

@rlibrary sf
#R"library(dplyr)"

#nc = R"st_read(system.file("shape/nc.shp")"