#!/usr/bin/env Rscript --vanilla
# chmod 744 intersect_360grid_gadm.r #Use to make executable

# This script implements the breezy philosophy: github.com/benscarlson/breezy

# ==== Breezy setup ====

'
Template
Usage:
intersect_360grid_gadm <out> [-t]
find_coverage (-h | --help)
Control files:
Parameters:
  out: output file path 
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
  
  .outPF <- file.path('/gpfs/ysm/project/jetz/ryo3/projects/data-coverage/analysis')
  .grid_id <- "v2"
  
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
  
  .outPF <- makePath(ag$out)
  .grid_id <- "v2"
}


#---- Initialize Environment ----#
# check if intersection exists
# if exists, don't run
if (file.exists(file.path(.outPF,"intersection-gadm-360grid.csv"))){
  message("intersection already exists...")
}else{


source(file.path(.wd,"projects/data-coverage/src/startup.r"))

#---- Perform analysis ----#

# GADM x 360 grid intersection

if (.grid_id == "v2") {
  
  message("reading in grid:")
  grid <- fread(paste0(.wd,"/projects/data-coverage/data/grid360_v2_geohash5/grid360v2_geohash5_prop.csv"))
  
  grid <- grid %>% 
    select(ID_360, geohash, prop) %>%
    rename(geom_id = ID_360)
  
}  else {
  
  grid_file_path <- file.path(.wd,"grid360/output/")
  
  # read in grid
  setwd(grid_file_path)
  files <- list.files(grid_file_path,pattern = "*.csv",full.names = FALSE)
  
  message("reading in grid:")
  start <- Sys.time()
  grid = data.table::rbindlist(lapply(files, data.table::fread))
  end <- Sys.time()
  print(end - start)
}
  


# read in GADM
gadm_file_path <- file.path(.wd,"gadm36/output/")
setwd(gadm_file_path)
files <- list.files(gadm_file_path,pattern = "*geohash5.csv",full.names = FALSE)

message("reading in GADM:")
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
message("joining GADM and 360 grid:")
grid_gadm_join <- dplyr::left_join(grid,gadm,by="geohash") %>%
  rename("hbwid" = "geom_id.x","country" = "name")

### find proportion of grid cell in country
# read in geohash areas
geohash_area <- data.table::fread(file.path(.wd,"geohash_area/geohash_area.csv"))

# find grid cell area based on geohashes
grid <- dplyr::left_join(grid,geohash_area,by="geohash") 
grid <- grid %>% 
  rename("hbwid" = "geom_id") %>%
  group_by(hbwid) %>% 
  summarise(area_grid = sum(prop*gh_area))

# find proportion of grid cell in country
# restrict to geohashes with equal proportion in grid cell and country 
# (otherwise cannot discriminate between non/overlapping geoms)
candidate_gh <- grid_gadm_join %>% 
  group_by(hbwid) %>% 
  filter(prop.x == prop.y) %>%
  dplyr::left_join(., geohash_area, by="geohash") 

# find area of grid cell in country (based on geohashes)
grid_gadm <- candidate_gh %>% 
  group_by(hbwid,country) %>% 
  summarise(area_grid_country = sum(prop.x*gh_area))

# join with grid cell areas
grid_gadm <- dplyr::left_join(grid_gadm, grid, by = "hbwid") %>%
  mutate(prop_grid_country = area_grid_country/area_grid)

#---- Save output ---#

message(glue("write out files to...",.outPF))
fwrite(candidate_gh,file.path(.outPF,"intersection-gadm-360grid-candidate-geohash.csv"))
fwrite(grid_gadm,file.path(.outPF,"intersection-gadm-360grid.csv"))

#---- Finalize script ----#

message("intersection complete!")
}