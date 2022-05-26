ENV["R_HOME"] = "C:\\Program Files\\R\\R-4.1.3"

using Pkg
#Pkg.add("RCall") #<- Essential
#Pkg.build("RCall") #<- Essential
using RCall

#ggplot(diamonds, aes(x=carat, y=price)) + geom_point() +  theme_bw()

