#!/usr/bin/env Rscript --vanilla
# chmod 744 find_coverage.r #Use to make executable

# This script implements the breezy philosophy: github.com/benscarlson/breezy

# ==== Breezy setup ====

'
Template
Usage:
find_coverage <taxa> <year1> <year2> <dataid> [-t]
find_coverage (-h | --help)
Parameters:
  taxa: taxa name. 
  year1: starting year.
  year2: ending year.
  dataid: id of occurrence dataset
Options:
-h --help     Show this screen.
-v --version     Show version.
-t --test         Indicates script is a test run, will not save output parameters or commit to git
' -> doc

#---- Input Parameters ----#
if(interactive()) {
  library(here)
  rm(list=ls())
  
  .wd <- '/gpfs/ysm/project/jetz/ryo3' 
  .test <- TRUE
  rd <- here::here
  
  # default to mammals 1950-2019
  .outPF <- file.path('/gpfs/ysm/project/jetz/ryo3/projects/data-coverage/analysis/coverage-output/')
  .taxa_name <- "birds"
  .year_start <- 1950
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

source(file.path(.wd,"projects/data-coverage/src/startup.r"))

#Source all files in the auto load funs directory
list.files(file.path(.wd,"projects/data-coverage/src/funs/auto"),full.names=TRUE) %>%
  walk(source)

message(glue("taxa: ",.taxa_name))
message(glue("start: ",.year_start))
message(glue("end: ",.year_end))
message(glue("dataset: ",.dataset_id))

##################################################
### occurrence data source

# 2020 data dump
if (.data_source == "202004"){
  gbif_file_path <- file.path(.wd,"gbif-data-202004",.taxa_name,"updated-files/")
  ebird_file_path <- file.path(.wd,"ebird-data-202003/updated-files/")
  wi_file_path <-   file.path(.wd,"wi-data/input-files/")
}

# 2018 data dump
if (.data_source == "201810"){
  gbif_file_path <- file.path(.wd,"gbif-data",.taxa_name,"updated-files/")
  ebird_file_path <- file.path(.wd,"ebird-data/updated-files/")
}
##################################################

##################################################
### taxa data

# pull synonym list
synlist <- prep_taxonomy(.taxa_name)

# pull species x 360 grid intersection
grid_ranges <- get_intersection(.taxa_name)

##################################################

if (.taxa_name == "birds"){
  
  message("get GBIF data...")
  gbif <- get_occurrence_data(gbif_file_path)
  
  message("prep GBIF data...")
  gbif_clean <- prep_occurrence_data(gbif)
  
  message("get eBird data...")
  ebird <- get_occurrence_data(ebird_file_path)
  
  message("prep GBIF data...")
  ebird_clean <- prep_occurrence_data(ebird)
  
}
