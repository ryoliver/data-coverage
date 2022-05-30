#---- Input Parameters ----#
if(interactive()) {
  library(here)
  rm(list=ls())
  
  .wd <- '~/Documents/Yale/projects/data-coverage/' 
  .test <- TRUE
  rd <- here::here
  
  # default to mammals 1950-2019
  .datPF <-"~/Documents/Yale/data-coverage/coverage_output/"
  .outPF <- paste0(.wd,'analysis/coverage-output/')
  
  .year_start <- 1990
  .year_end <- 2019
  .data_source <- "202004"
  .dataset_id <- "gbif"
  
} else {
  library(docopt)
  library(rprojroot)
  library(whereami)
  
  ag <- docopt(doc, version = '0.1\n')
  .wd <- '/gpfs/ysm/project/jetz/ryo3' 
  .script <-  whereami::thisfile()
  .test <- as.logical(ag$test)
  rd <- is_rstudio_project$make_fix_file(.script)
  
  source(file.path(.wd,"projects/data-coverage/src/funs/input_parse.r"))
  
  .outPF <- file.path('/gpfs/ysm/project/jetz/ryo3/projects/data-coverage/analysis/coverage-output/')
  .taxa_name <- ag$taxa
  .year_start <- as.numeric(ag$year1)
  .year_end <- as.numeric(ag$year2)
  .data_source <- "202004"
  .dataset_id <- ag$dataid
}


#---- Initialize Environment ----#
t0 <- Sys.time()

source(file.path(.wd,"src/startup.r"))

#Source all files in the auto load funs directory
list.files(file.path(.wd,"src/funs/auto"),full.names=TRUE) %>%
  walk(source)

taxa_name <- "birds"
get_data <- function(taxa_name){
  d <- fread(paste0(.datPF, taxa_name, "_species_coverage_",.data_source,".csv")) %>%
    filter(year >= .year_start) %>%
    filter(year <= .year_end) %>%
    group_by(scientificname) %>%
    summarise("n_records" = sum(n_records))
}

b <- get_data("birds")
m <- get_data("mammals")
a <- get_data("amphibians")
r <- get_data("reptiles")

d <- rbind(b,m,a,r) 


d %>%
  group_by(group = cut(n_records, breaks = c(seq(from = 0, to = 50, by = 10), c(100,1000,10000,100000,1000000,10000000)), right = FALSE)) %>%
  filter(is.na(group))


d %>%
  group_by(group = cut(n_records, breaks = c(seq(from = 0, to = 50, by = 10), c(100,1000,10000,100000,1000000,10000000)), right = FALSE)) %>%
  summarise("n_species" = n_distinct(scientificname))

p <- ggplot(data = d) +
  geom_histogram(aes(n_records)) +
  scale_x_continuous(trans = 'log10')

pg <- ggplot_build(p)


pg$data[[1]]
