ENV["R_HOME"] = "C:\\Program Files\\R\\R-4.1.3" ## Windows
#ENV["R_HOME"] = "/Library/Frameworks/R.framework/Resources" ##MacOSX

using Pkg
using RCall
using Plots

@rlibrary sf
#R"library(dplyr)"
R"library(sf)"


#https://youtu.be/yPaEB6er2Iw

