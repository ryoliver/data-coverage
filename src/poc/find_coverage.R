#!/usr/bin/env Rscript --vanilla
# chmod 744 find_coverage.r #Use to make executable

# This script implements the breezy philosophy: github.com/benscarlson/breezy

# ==== Breezy setup ====

'
Template
Usage:
find_coverage <taxa> <year1> <year2> <dataid> [-t]
find_coverage (-h | --help)
Control files:
  ctfs/individual.csv
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
  .outPF <- file.path('/gpfs/ysm/scratch60/jetz/ryo3/coverage_output')
  .taxa_name <- "mammals"
  .year_start <- 1950
  .year_end <- 2019
  .data_source <- "202004"

} else {
  library(docopt)
  library(rprojroot)
  library(whereami)
  
  ag <- docopt(doc, version = '0.1\n')
  .wd <- '/gpfs/ysm/project/jetz/ryo3' 
  .script <-  whereami::thisfile()
  .test <- as.logical(ag$test)
  rd <- is_rstudio_project$make_fix_file(.script)
  
  source(rd('src/funs/input_parse.r'))
  
  #.datPF <- makePath(ag$dat)
  #.outPF <- makePath(ag$out)
  .taxa_name <- ag$taxa
  .year_start <- as.numeric(ag$year1)
  .year_end <- as.numeric(ag$year2)
  .data_source <- ag$dataid
}


#---- Initialize Environment ----#
t0 <- Sys.time()

source(rd('src/startup.r'))

#Source all files in the auto load funs directory
list.files(rd('src/funs/auto'),full.names=TRUE) %>%
  walk(source)


message(glue("taxa: ",.taxa_name))
message(glue("start: ",.year_start))
message(glue("end: ",.year_end))


##################################################
### occurrence data source

# 2020 data dump
if (data_source == "202004"){
  gbif_file_path <- file.path(.wd,"gbif-data-202004",.taxa_name,"updated-files/")
  ebird_file_path <- file.path(.wd,"ebird-data-202003/updated-files/")
  wi_file_path <-   file.path(.wd,"wi-data")
}

# 2018 data dump
if (data_source == "201810"){
  gbif_file_path <- file.path(.wd,"gbif-data",.taxa_name,"updated-files/")
  ebird_file_path <- file.path(.wd,"ebird-data/updated-files/")
}
##################################################

##################################################
### synonym list
# pull synonym list
synlist <- prep_taxonomy(.taxa_name)

# species x 360 grid intersection
grid_ranges <- get_intersection(.taxa_name)



##################################################


##################################################
### expected occurrence
# GADM x 360 grid intersection

grid_file_path <- file.path(.wd,"grid360/output/")

# read in grid
setwd(grid_file_path)
files <- list.files(grid_file_path,pattern = "*.csv",full.names = FALSE)

print("reading in grid:")
start <- Sys.time()
grid = data.table::rbindlist(lapply(files, data.table::fread))
end <- Sys.time()
print(end - start)

# read in GADM
gadm_file_path <- file.path(.wd,"gadm36/output/")
setwd(gadm_file_path)
files <- list.files(gadm_file_path,pattern = "*geohash5.csv",full.names = FALSE)

print("reading in GADM:")
start <- Sys.time()
gadm = rbindlist(lapply(files, data.table::fread))
end <- Sys.time()
print(end - start)

# filter geohashes with less than 50% of area in country
gadm <- gadm %>% filter(prop >= 0.5)

# read in country names (linked to geom ids)
gadm_names <- read.csv(file.path(.wd,"gadm36/input/gadm36_list.csv"),stringsAsFactors = FALSE)
gadm <- dplyr::left_join(gadm,gadm_names,by= "geom_id")

# join GADM with 360 grid
print("joining GADM and 360 grid:")
grid_gadm_join <- dplyr::left_join(grid,gadm,by="geohash") %>%
  rename("hbwid" = "geom_id.x","country" = "name")

### find proportion of grid cell in country
# read in geohash areas
geohash_area <- data.table::fread(file.path(.wd,"geohash_area/geohash_area.csv"))

# find grid cell area based on geohashes
grid <- dplyr::left_join(grid,geohash_area,by="geohash") 
grid <- grid %>% rename("hbwid" = "geom_id") %>%
  group_by(hbwid) %>% summarise(area_grid = sum(prop*gh_area))

print("360 grid area (km2):")
range(grid$area_grid)

# find proportion of grid cell in country
# restrict to geohashes with equal proportion in grid cell and country 
# (otherwise cannot discriminate between non/overlapping geoms)
candidate_gh <- grid_gadm_join %>% group_by(hbwid) %>% filter(prop.x == prop.y)
candidate_gh <- dplyr::left_join(candidate_gh, geohash_area, by="geohash") 

# find area of grid cell in country (based on geohashes)
grid_gadm <- candidate_gh %>% group_by(hbwid,country) %>% 
  summarise(area_grid_country = sum(prop.x*gh_area))

# join with grid cell areas
grid_gadm <- dplyr::left_join(grid_gadm, grid, by = "hbwid") %>%
  mutate(prop_grid_country = area_grid_country/area_grid)

fwrite(grid_gadm,paste0(output_file_path,"gadm-360grid-area-summary.csv"))


## find expected species in each grid cell
grid_gadm_ranges <- dplyr::left_join(grid_gadm,grid_ranges,by = "hbwid") %>% filter(!is.na(scientificname))


### grid level
# find number of species expected in each grid cell in each country
grid.expected <- grid_gadm_ranges %>% 
  group_by(country,hbwid) %>%
  summarise(Egi = n_distinct(scientificname))

grid.expected.expanded <- grid.expected %>% 
  tidyr::expand(nesting(country,hbwid,Egi),year = year_start:year_end)

### national level
# find number of grid cells of expected occurrence for each species in each country
#country.expected <- grid_gadm_ranges %>% dplyr::group_by(country,scientificname) %>% dplyr::summarise(Eci = n_distinct(hbwid))
country.expected <- grid_gadm_ranges %>% 
  group_by(country,scientificname) %>% 
  distinct(hbwid,.keep_all=TRUE) %>% 
  summarise(Eci = sum(prop_grid_country))

country.expected.expanded <- country.expected %>% 
  tidyr::expand(nesting(country,scientificname,Eci),year = year_start:year_end)

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

fwrite(country.stewardship,paste0(output_file_path,taxa_name,"_country_stewardship.csv"))


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

if (taxa_name == "birds"){
  gbif <- get_occurrence_data(gbif_file_path)
  gbif_clean <- prep_occurrence_data(gbif)
  
  ebird <- get_occurrence_data(ebird_file_path)
  ebird_clean <- prep_occurrence_data(ebird)
  
  print("combining datasets...")
  pts <- rbind(gbif_clean,ebird_clean)
  
  #gbif <- gbif %>% select(scientificname,latitude,longitude,eventDate,geohash,year)
  #ebird <- ebird %>% select(scientificname,geohash,year)
  
  colnames(gbif) <- tolower(colnames(gbif))
  colnames(ebird) <- tolower(colnames(ebird))
  
  pts_raw <- rbind(gbif,ebird)
}else{
  pts_raw <- get_occurrence_data(gbif_file_path)
  pts <- prep_occurrence_data(pts_raw)
}





##################################################

# prep occurrence data for summaries
summary_data <- prep_data_summary(pts_raw)

# compute data summaries
print("compute data summaries...")
species_national_data_summary <-  summarize_species_national_data(summary_data)
species_data_summary <- summarize_species_data(summary_data)
grid_national_data_summary <- summarize_grid_national_data(summary_data)
grid_data_summary <- summarize_grid_data(summary_data)

species_grid_national_data_summary <- summarize_species_grid_national_data(summary_data)
fwrite(species_grid_national_data_summary,paste0(output_file_path,taxa_name,"_species_grid_data_summary_",data_source,".csv"))

# find coverage!

print("finding national coverage...")
national_coverage <- find_national_coverage(pts)
fwrite(national_coverage,paste0(output_file_path,taxa_name,"_national_coverage_",data_source,".csv"))

print("finding species coverage...")
species_coverage <- find_species_coverage(pts)
fwrite(species_coverage,paste0(output_file_path,taxa_name,"_species_coverage_",data_source,".csv"))

print("finding grid+national coverage...")
grid_national_coverage <- find_grid_national_coverage(pts)
fwrite(grid_national_coverage,paste0(output_file_path,taxa_name,"_grid_national_coverage_",data_source,".csv"))

print("finding grid coverage...")
grid_coverage <- find_grid_coverage(pts)
fwrite(grid_coverage,paste0(output_file_path,taxa_name,"_grid_coverage_",data_source,".csv"))
