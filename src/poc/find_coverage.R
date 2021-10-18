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


##################################################
### finding expected occurrence

# pull GADM x 360 grid intersection
grid_gadm <- fread(file.path(.wd,"projects/data-coverage/analysis/intersection-gadm-360grid.csv"))

# pull candidate geohashes for intersection
candidate_gh <- fread(file.path(.wd,"projects/data-coverage/analysis/intersection-gadm-360grid-candidate-geohash.csv"))

## find expected species in each grid cell
grid_gadm_ranges <- dplyr::left_join(grid_gadm,grid_ranges,by = "hbwid") %>% 
  filter(!is.na(scientificname))

### grid level
# find number of species expected in each grid cell in each country
grid.expected <- grid_gadm_ranges %>% 
  group_by(country,hbwid) %>%
  summarise(Egi = n_distinct(scientificname))

grid.expected.expanded <- grid.expected %>% 
  tidyr::expand(nesting(country,hbwid,Egi),year = .year_start:.year_end)

### national level
# find number of grid cells of expected occurrence for each species in each country
#country.expected <- grid_gadm_ranges %>% dplyr::group_by(country,scientificname) %>% dplyr::summarise(Eci = n_distinct(hbwid))
country.expected <- grid_gadm_ranges %>% 
  group_by(country,scientificname) %>% 
  distinct(hbwid,.keep_all=TRUE) %>% 
  summarise(Eci = sum(prop_grid_country))

country.expected.expanded <- country.expected %>% 
  tidyr::expand(nesting(country,scientificname,Eci),year = .year_start:.year_end)

# find number of grid cells of expected occurrence for each species globally
#global.expected <- country.expected %>% group_by(scientificname) %>% dplyr::summarise(Eki = sum(Eci))
global.expected <- grid_gadm_ranges %>% 
  group_by(scientificname) %>% 
  summarise(Eki = n_distinct(hbwid))

# link country and global range sizes for each species
species.expected <- dplyr::left_join(country.expected.expanded,global.expected,by="scientificname") # DOES THIS NEED TO INCLUDE YEAR?

# find stewardship of each species in each country
# number of grid cells of expected occurrence for each species within a country vs. globally
species.expected$Eci_Eki <- species.expected$Eci/species.expected$Eki


# find national stewardship of all species expected in country
country.stewardship <- species.expected %>% 
  distinct(country,scientificname,.keep_all= TRUE) %>% 
  group_by(country) %>% 
  dplyr::summarise(Ecl_Ekl = sum(Eci_Eki))


fwrite(country.stewardship,paste0(.outPF,.taxa_name,"_country_stewardship.csv"))


# rows: every country + expected species pair (expanded so there is a record for every year of the observation record)
# columns:
#   Eci = # of expected grid cells for species i in country c
#   Eki = # of expected grid cells for species i globally
#   Ecl = # of expected grid cells for all species in country c
#   Ekl = # of expected grid cells for all species in country c globally
expected <- dplyr::left_join(species.expected,country.stewardship,by="country")
##################################################


##################################################
### observations
##################################################



# get occurrence data
if(.dataset_id == "gbif"){
  if (.taxa_name == "birds"){
    
    file_path <- gbif_file_path
    # read in files
    setwd(file_path)
    files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
    
    message("reading in GBIF observations...")
    gbif = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
    message(glue(nrow(gbif)," GBIF records"))

    file_path <- ebird_file_path
    setwd(file_path)
    files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
    
    message("reading in eBird observations...")
    ebird = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
    message(glue(nrow(ebird)," eBird records"))
    
    
    message("checking column names...")
    colnames(gbif) <- tolower(colnames(gbif))
    colnames(ebird) <- tolower(colnames(ebird))
    
    #message("checking date format...")
    #gbif$eventdate <- as.character(gbif$eventdate)
    #ebird$eventdate <- as.character(ebird$eventdate)
  

    #message("reading in GBIF data...")
    #gbif <- get_occurrence_data(gbif_file_path)
    
    #message("reading in eBird data...")
    #ebird <- get_occurrence_data(ebird_file_path)
    
    message("combining GBIF and eBird data...")
    pts_raw <- rbind(gbif,ebird)
    
    message(glue(nrow(pts_raw)," total records"))
    
    
    message("cleaning occurrence data...")
    pts <- prep_occurrence_data(pts_raw)
  }else{
    message("reading in GBIF data...")
    pts_raw <- get_occurrence_data(gbif_file_path)
    
    message("cleaning occurrence data...")
    pts <- prep_occurrence_data(pts_raw)
  }
} 
if(.dataset_id == "wi"){  
  message("reading in WI data...")
  pts_raw <- get_occurrence_data(wi_file_path)
  
  message("cleaning occurrence data...")
  pts <- prep_occurrence_data(pts_raw)
} 
if(.dataset_id == "gbif-wi"){
  if (.taxa_name == "birds"){
    message("reading in GBIF data...")
    gbif <- get_occurrence_data(gbif_file_path)
    
    message("reading in eBird data...")
    ebird <- get_occurrence_data(ebird_file_path)
    
    message("reading in WI data...")
    wi <- get_occurrence_data(wi_file_path)
    
    message("combining GBIF, eBird, and WI data...")
    pts_raw <- rbind(gbif,ebird,wi)
    
    message("cleaning occurrence data...")
    pts <- prep_occurrence_data(pts_raw)
  }else{
    message("reading in GBIF data...")
    gbif <- get_occurrence_data(gbif_file_path)
    
    message("reading in WI data...")
    wi <- get_occurrence_data(wi_file_path)
    
    message("combining GBIF and WI data...")
    pts_raw <- rbind(gbif,wi)
    
    message("cleaning occurrence data...")
    pts <- prep_occurrence_data(pts_raw)
  }
}



##################################################
### find coverage
# prep occurrence data for summaries
summary_data <- prep_data_summary(pts_raw)

# compute data summaries
message("compute data summaries...")
species_national_data_summary <-  summarize_species_national_data(summary_data)
species_data_summary <- summarize_species_data(summary_data)
grid_national_data_summary <- summarize_grid_national_data(summary_data)
grid_data_summary <- summarize_grid_data(summary_data)

species_grid_national_data_summary <- summarize_species_grid_national_data(summary_data)
fwrite(species_grid_national_data_summary,paste0(.outPF,.taxa_name,"_species_grid_data_summary_",.dataset_id,"_",.data_source,".csv"))

# find coverage!

message("finding national coverage...")
national_coverage <- find_national_coverage(pts)
fwrite(national_coverage,paste0(.outPF,.taxa_name,"_national_coverage_",.dataset_id,"_",.data_source,".csv"))

message("finding species coverage...")
species_coverage <- find_species_coverage(pts)
fwrite(species_coverage,paste0(.outPF,.taxa_name,"_species_coverage_",.dataset_id,"_",.data_source,".csv"))

message("finding grid+national coverage...")
grid_national_coverage <- find_grid_national_coverage(pts)
fwrite(grid_national_coverage,paste0(.outPF,.taxa_name,"_grid_national_coverage_",.dataset_id,"_",.data_source,".csv"))

message("finding grid coverage...")
grid_coverage <- find_grid_coverage(pts)
fwrite(grid_coverage,paste0(.outPF,.taxa_name,"_grid_coverage_",.dataset_id,"_",.data_source,".csv"))

message(glue("coverage complete for ",.taxa_name," ",.year_start,"-",.year_end, " using ",.dataset_id))