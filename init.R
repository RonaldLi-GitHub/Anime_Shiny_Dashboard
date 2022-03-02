# init.R
#
# Example R code to install packages if not already installed
#
my_packages = c("shinyjs", "stringr", "plotly", "shinyWidgets", "ggplot2",
                "dplyr", "stringdist", "scales","devtools", "shinydashboard",
                "shinyvalidate", "wordcloud", "summaryBox")

install_if_missing = function(p) {
  if (p %in% rownames(installed.packages()) == FALSE & p !="summaryBox") {
    install.packages(p)
  }
  if (p %in% rownames(installed.packages()) == FALSE & p =="summaryBox") {
    remotes::install_github("deepanshu88/summaryBox")
  }
}

invisible(sapply(my_packages, install_if_missing))