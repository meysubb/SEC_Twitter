my_packages <- c("dplyr","ggplot2","rtweet","lubridate",'rvest')
install_if_missing <- function(p) {
  if(p %in% rownames(installed.packages())==FALSE){
    install.packages(p)}
}

invisible(sapply(my_packages, install_if_missing))

dev_packages <- c("lbenz730/ncaahoopR","jflancer/bigballR")

dev_install <- function(p){
  devtools::install_github(p)
}

invisible(sapply(dev_packages,dev_install))