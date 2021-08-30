#!/usr/bin/env Rscript --vanilla
# chmod 744 find_coverage.r #Use to make executable

# This script implements the breezy philosophy: github.com/benscarlson/breezy

# ==== Breezy setup ====

'
Template
Usage:
find_coverage <taxa> <year1> <year2> [--db=<db>] [-t]
find_coverage (-h | --help)
Control files:
  ctfs/individual.csv
Parameters:
  dat: path to input csv file. 
  out: path to output directory.
Options:
-h --help     Show this screen.
-v --version     Show version.
-t --test         Indicates script is a test run, will not save output parameters or commit to git
' -> doc

#---- Input Parameters ----#
if(interactive()) {
  library(here)
  
  .wd <- '~/Documents/Yale/projects/easy-breezy' #UPDATE
  .test <- TRUE
  rd <- here::here
  
  .outPF <- file.path('/gpfs/ysm/scratch60/jetz/ryo3/coverage_output')

} else {
  library(docopt)
  library(rprojroot)
  library(whereami)
  
  ag <- docopt(doc, version = '0.1\n')
  .wd <- getwd()
  .script <-  whereami::thisfile()
  .test <- as.logical(ag$test)
  rd <- is_rstudio_project$make_fix_file(.script)
  
  source(rd('src/funs/input_parse.r'))
  
  #.datPF <- makePath(ag$dat)
  #.outPF <- makePath(ag$out)
  .taxa_name <- ag$taxa
  .year_start <- as.numeric(ag$year1)
  .year_end <- as.numeric(ag$year2)
  
}

message(.taxa_name)
message(.year_start)
message(.year_end)
message(.year_start + .year_end)

if (1 == 2){
  


##################################################
### set time span and output file path
year_start <- 1950
year_end <- 2019
output_file_path <- "/home/ryo3/scratch60/coverage_output/"
##################################################

##################################################
### occurrence data source
data_source <- "202004"

# 2020 data dump
if (data_source == "202004"){
  gbif_file_path <- paste0("/home/ryo3/project/gbif-data-202004/",taxa_name,"/updated-files/")
  ebird_file_path <- "/home/ryo3/project/ebird-data-202003/updated-files/"
  wi_file_path <- "/home/ryo3/project/wi-data"
}

# 2018 data dump
if (data_source == "201810"){
  gbif_file_path <- paste0("/home/ryo3/project/gbif-data/",taxa_name,"/updated-files/")
  ebird_file_path <- "/home/ryo3/project/ebird-data/updated-files/"
}
##################################################

##################################################
### synonym lists
# function to convert double list format synonym lists
convert_synlist <- function(file_name){
  synlist <- fread(file_name)
  
  names(synlist) <- tolower(names(synlist))
  
  accepted <- synlist %>% filter(accid == 0)
  synonym <- synlist %>% filter(accid > 0)
  accepted_dup <- accepted
  accepted_dup$accid <- accepted_dup$id
  syns_all <- rbind(synonym,accepted_dup)
  
  synlist <- left_join(accepted,syns_all,by=c("id" = "accid")) 
  
  synlist <- synlist %>%
    select(canonical.x,canonical.y) %>%
    rename("Accepted" = canonical.x, "Synonym" = canonical.y) %>%
    distinct(Accepted,Synonym) %>% 
    group_by(Synonym) %>%
    mutate("U.or.A" = if_else(n() == 1, "U","A")) %>%
    ungroup()
}

# synonym list directory/file names
synlist_dir <- "/home/ryo3/scratch60/synonym-lists/"

if(taxa_name == "amphibians"){
  synlist_file <- paste0(synlist_dir,"Amphibians_20191210.csv")
  synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
}

if(taxa_name == "birds"){
  synlist_file <- paste0(synlist_dir,"Birds_20191204.csv")
  synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
  
  syns_birds_manual <- data.frame("Accepted" = c("Ardea albus",
                                                 "Ardea albus",
                                                 "Anas poecilorhyncha",
                                                 "Haliaeetus ichthyaetus",
                                                 "Butorides virescens",
                                                 "Colaptes auratus",
                                                 "Buteo rufinus",
                                                 "Psophia crepitans",
                                                 "Cinclodes fuscus",
                                                 "Hydrornis guajanus",
                                                 "Alethe diademata",
                                                 "Neomorphus squamiger",
                                                 "Psophia viridis",
                                                 "Turdus nudigenis"),
                                  "Synonym" = c("Ardea modestus",
                                                "Ardea albus",
                                                "Anas poecilorhyncha",
                                                "Icthyophaga ichthyaetus",
                                                "Butorides virescens",
                                                "Colaptes cafer",
                                                "Buteo rufinus",
                                                "Psophia ochroptera",
                                                "Cinclodes fuscus",
                                                "Pitta guajana",
                                                "Alethe castanea",
                                                "Neomorphus squamiger",
                                                "Psophia obscura",
                                                "Turdus nudigenis")) %>%
    mutate("U.or.A" = rep("U",nrow(.)))
  synlist <- rbind(synlist,syns_birds_manual)
}
  
if(taxa_name == "mammals"){
  synlist_file <- paste0(synlist_dir,"Mammal_20191204.csv")
  synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
}

if(taxa_name == "reptiles"){
  synlist_file <- paste0(synlist_dir,"Reptile_20191211.csv")
  synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
}
##################################################


##################################################
### expected occurrence
# GADM x 360 grid intersection
grid_file_path <- "/home/ryo3/project/grid360/output/"

# read in grid
setwd(grid_file_path)
files <- list.files(grid_file_path,pattern = "*.csv",full.names = FALSE)

print("reading in grid:")
start <- Sys.time()
grid = data.table::rbindlist(lapply(files, data.table::fread))
end <- Sys.time()
print(end - start)

# read in GADM
gadm_file_path <- "/home/ryo3/project/gadm36/output"
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
gadm_names <- read.csv("/home/ryo3/project/gadm36/input/gadm36_list.csv",stringsAsFactors = FALSE)
gadm <- dplyr::left_join(gadm,gadm_names,by= "geom_id")

# join GADM with 360 grid
print("joining GADM and 360 grid:")
grid_gadm_join <- dplyr::left_join(grid,gadm,by="geohash") %>%
  rename("hbwid" = "geom_id.x","country" = "name")

  
### find proportion of grid cell in country
# read in geohash areas
geohash_area <- data.table::fread("/home/ryo3/project/geohash_area/geohash_area.csv")

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


print("proportion of 360 grid cell in country:")
range(grid_gadm$prop_grid_country)

test <- grid_gadm %>% filter(prop_grid_country > 1)
if (nrow(test) > 1){
  print("ERROR: proportion of grid cell in country")
}else {
  print("OK: proportion of grid cell in country")
}



# species x 360 grid intersection
if (taxa_name == "amphibians"){
  grid.ranges.df <- read.csv("/home/ryo3/project/geohash_grid_range_join/amphibians_360grid_join.csv",stringsAsFactors = FALSE)
  grid_ranges <- rename(grid.ranges.df,"hbwid" = "geom_id")
  
  grid_ranges = dplyr::left_join(grid_ranges,synlist,by=c("scientificname"="Synonym")) %>% 
    filter(!is.na(Accepted)) %>% 
    select(hbwid,Accepted) %>%
    rename("scientificname" = "Accepted") 
}

if (taxa_name == "birds"){
  grid.ranges.df <- read.csv("/home/ryo3/project/geohash_grid_range_join/birds_360grid_join.csv",stringsAsFactors = FALSE)
  grid_ranges <- grid.ranges.df %>%
    filter(seasonality %in% c(1,2))
  
  #grid_ranges <- fread("/home/ryo3/project/geohash_grid_range_join/birds_360grid_MOL_202010.csv") %>%
  #  filter(season %in% c(1,2)) %>%
  #  select(sciname,ID_360) %>%
  #  rename("scientificname" = "sciname",
  #         "hbwid" = "ID_360")
  
  grid_ranges = dplyr::left_join(grid_ranges,synlist,by=c("scientificname"="Synonym")) %>% 
    filter(!is.na(Accepted)) %>% 
    select(hbwid,Accepted) %>%
    rename("scientificname" = "Accepted") 
}

if (taxa_name == "mammals"){
  grid.ranges.df <- read.csv("/home/ryo3/project/geohash_grid_range_join/mammals_360grid_join.csv",stringsAsFactors = FALSE)
  grid_ranges <- rename(grid.ranges.df,"hbwid" = "geom_id")
  
  grid_ranges = dplyr::left_join(grid_ranges,synlist,by=c("scientificname"="Synonym")) %>% 
    filter(!is.na(Accepted)) %>% 
    select(hbwid,Accepted) %>%
    rename("scientificname" = "Accepted") 
}


if (taxa_name == "reptiles"){
  grid.ranges.df <- read.csv("/home/ryo3/project/geohash_grid_range_join/gard_reptiles_360grid_join.csv",stringsAsFactors = FALSE)
  grid_ranges <- rename(grid.ranges.df,"hbwid" = "geom_id")
  
  grid_ranges = dplyr::left_join(grid_ranges,synlist,by=c("scientificname"="Synonym")) %>% 
    filter(!is.na(Accepted)) %>% 
    select(hbwid,Accepted) %>%
    rename("scientificname" = "Accepted") 
}


## find expected species in each grid cell
grid_gadm_ranges <- dplyr::left_join(grid_gadm,grid_ranges,by = "hbwid") %>% filter(!is.na(scientificname))
fwrite(grid_gadm_ranges,paste0("/home/ryo3/project/geohash_grid_range_join/",taxa_name,"_360grid_gadm_join.csv"))


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
#species.expected <- dplyr::left_join(country.expected,global.expected,by="scientificname") # DOES THIS NEED TO INCLUDE YEAR?


# find stewardship of each species in each country
# number of grid cells of expected occurence for each species within a country vs. globally
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
### data processing functions
##################################################

### processing occurrence data
prep_occurrence_data <- function(occ_data){
  
  occ_data <- occ_data %>% filter(year >= year_start) 
  
  # find distinct records
  print("finding distinct observations...")
  occ_data <- occ_data %>% distinct(scientificname,geohash,year,.keep_all = TRUE)
  
  # join observations with synonym list
  print("joining with synonym list...")
  occ_syn_join=dplyr::left_join(occ_data,synlist,by=c("scientificname"="Synonym"))
  
  # filter out observations without synonym match or date
  occ_data <- occ_syn_join %>% filter(!is.na(Accepted)) %>% 
    select(year,Accepted,geohash) %>%
    rename("scientificname" = "Accepted") %>%
    distinct(scientificname,year,geohash)
  
  print("joining observations with 360 grid x GADM...")
  #grid_gadm_occ <-  dplyr::left_join(grid_gadm_join,occ_data,by="geohash") %>%
    #filter(!is.na(scientificname)) %>%
    #distinct(hbwid,country,scientificname,year)
  
  # filter to just geohashes where intersection could be confirmed
  # more conservative than approach above
  grid_gadm_occ <- left_join(occ_data,candidate_gh, by = "geohash") %>%
    filter(!is.na(hbwid)) %>%
    filter(!is.na(country)) %>%
    distinct(hbwid,country,scientificname,year)
  
  # join with expected grid cells to restrict observations only within ranges
  print("filtering to observations within range...")
  range_obs_join <- dplyr::left_join(grid_gadm_ranges,grid_gadm_occ,by=c("hbwid","country","scientificname"))
  occ_data <- range_obs_join %>% 
    filter(!is.na(year)) %>%
    distinct(hbwid,country,scientificname,year,.keep_all = TRUE)

  return(occ_data)
}



prep_data_summary <- function(occ_data){
  
  record_summary <- data.frame("total" = c(0), "no_dups" = c(0), "valid" = c(0))
  record_summary$total <- nrow(occ_data)
  
  occ_data <- occ_data %>% 
    filter(year >= year_start) %>%
    distinct(scientificname,latitude,longitude,eventdate, .keep_all = TRUE) %>%
    select(scientificname,geohash,year)
  
  record_summary$no_dups <- nrow(occ_data)
  
  # join observations with synonym list
  occ_syn_join=dplyr::left_join(occ_data,synlist,by=c("scientificname"="Synonym"))
  
  # filter out observations without synonym match or date
  occ_data <- occ_syn_join %>% filter(!is.na(Accepted)) %>% 
    select(Accepted,geohash,year) %>%
    rename("scientificname" = "Accepted") 
  
  grid_gadm_occ <- left_join(occ_data,candidate_gh, by = "geohash") %>%
    filter(!is.na(hbwid)) %>%
    filter(!is.na(country)) %>%
    select(country,hbwid,scientificname,year)
  
  # join with expected grid cells to restrict observations only within ranges
  range_obs_join <- dplyr::left_join(grid_gadm_ranges,grid_gadm_occ,by=c("hbwid","country","scientificname")) 
  occ_data <- range_obs_join %>% 
    filter(!is.na(year)) %>%
    select(hbwid,country,scientificname,year)
  
  record_summary$valid <- nrow(occ_data)
  fwrite(record_summary,paste0(output_file_path,taxa_name,"_record_summary_",data_source,".csv"))
  
  return(occ_data)
}

summarize_species_national_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(country,scientificname,year) %>%
    summarise("n_records" = n(),
              "n_unique" = n_distinct(country,hbwid,scientificname,year))
  return(summary)
}


summarize_species_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(scientificname,year) %>%
    summarise("n_records" = n(),
              "n_unique" = n_distinct(hbwid,scientificname,year))
  return(summary)
}


summarize_species_grid_national_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(country,hbwid,scientificname,year) %>%
    summarise("n_records" = n())
  return(summary)
}


summarize_grid_national_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(country,hbwid,year) %>%
    summarise("n_records" = n())
  return(summary)
}

summarize_grid_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(hbwid,year) %>%
    summarise("n_records" = n())
  return(summary)
}


find_national_coverage <- function(occ_data){
  
  # find number of grid cells of observed occurrence for each species in each country
  country.observed <- occ_data %>% 
    group_by(country,scientificname,year) %>% 
    distinct(hbwid,.keep_all=TRUE) %>% 
    summarise(Oci = sum(prop_grid_country))
  
  country.species <- dplyr::left_join(expected,country.observed,by = c("country","scientificname","year")) %>% 
    filter(!is.na(scientificname))
  
  country.species$Oci <- country.species$Oci %>% replace_na(0)
  
  # find proportion of # of grid cells with observations to # of grid cells with expected occurrence for each species
  country.species <- country.species %>% 
    dplyr::mutate(Oci_Eci = Oci/Eci)
  
  country.species <- left_join(country.species,species_national_data_summary, by = c("country","scientificname","year"))
  country.species <- country.species %>%
    mutate(n_records = ifelse(is.na(n_records),0,n_records),
           n_unique = ifelse(is.na(n_unique),0,n_unique))
  
  country.species <- country.species %>%
    mutate(prop_unique = n_unique/n_records)
  
  # write out species level coverage within nations
  fwrite(country.species,paste0(output_file_path,taxa_name,"_species_national_coverage_",data_source,".csv"))
  
  # replace prop unique for species with 1 record with NA so they over-inflate the national average
  country.species <- country.species %>%
    mutate(prop_unique = ifelse(n_records == 1,NA,prop_unique))
    
  # find national coverage values
  coverage <- country.species %>% 
    group_by(country,year) %>% 
    summarise(ssii1 = mean(Oci_Eci,na.rm=TRUE), 
              ssii2 = sum(Oci/sum(Eci,na.rm=TRUE),na.rm=TRUE),
              ssii3 = sum(Oci_Eci*(Eci_Eki/Ecl_Ekl),na.rm=TRUE),
              ssii4 = sum(Oci*Eci_Eki/sum(Eci*Eci_Eki,na.rm = TRUE),na.rm = TRUE),
              n_records = sum(n_records),
              prop_unique = mean(prop_unique,na.rm =TRUE)) 

  return(coverage)
}


find_species_coverage <- function(occ_data){
  # find number of grid cells of observed occurrence for each species in each country
  observed <- occ_data %>% 
    group_by(scientificname,year) %>% 
    distinct(hbwid,.keep_all=TRUE) %>% 
    summarise(Oi = sum(prop_grid_country))
  
  expected <- expected %>% 
    ungroup(country) %>% 
    select(scientificname,year,Eki) %>%
    expand(nesting(scientificname,Eki),year = year_start:year_end) %>%
    distinct(scientificname, year, .keep_all = TRUE)
  
  species <- dplyr::left_join(expected,observed,by = c("scientificname","year"))
  species$Oi <- species$Oi %>% replace_na(0)
  
  # find proportion of # of grid cells with observations to # of grid cells with expected occurrence for each species
  species <- species %>% dplyr::mutate(Oi_Eki = Oi/Eki)
  
  # join with species data summary
  species <- left_join(species,species_data_summary, by = c("scientificname","year"))
  
  species <- species %>%
    mutate(n_records = ifelse(is.na(n_records),0,n_records),
           n_unique = ifelse(is.na(n_unique),0,n_unique)) %>%
    mutate(prop_unique = n_unique/n_records) 
  
  return(species)
}


find_grid_national_coverage <- function(occ_data){
  
  # find number of species observed in each grid cell
  grid.observed <- occ_data %>% 
    group_by(country,hbwid,year) %>% 
    summarise(Ogi = n_distinct(scientificname))
  
  coverage <- dplyr::left_join(grid.expected.expanded,grid.observed,by = c("country","hbwid","year")) 
  
  coverage$Ogi <- coverage$Ogi%>% replace_na(0)
  
  coverage <- coverage %>%
    mutate(Ogi_Egi = Ogi/Egi) 
  
  # assemblage-level weighted by national stewardship
  observed <- left_join(occ_data,species.expected,by = c("scientificname","country","year")) %>%
    filter(!is.na(scientificname)) %>%
    distinct(scientificname,.keep_all = TRUE) %>%
    group_by(country,hbwid,year) %>%
    summarise(Ogsi = sum(Eci_Eki, na.rm = TRUE))
  
  expected.grid <- left_join(grid_gadm_ranges, species.expected, by = c("scientificname","country")) %>%
    filter(!is.na(scientificname)) %>%
    distinct(scientificname,.keep_all = TRUE) %>%
    group_by(hbwid,country) %>%
    summarise(Egsi = sum(Eci_Eki, na.rm = TRUE)) %>%
    expand(nesting(hbwid,country,Egsi),year = year_start:year_end)
  
  
  coverage_steward <- left_join(expected.grid,observed,by = c("country","hbwid","year"))
  coverage_steward$Ogsi <- coverage_steward$Ogsi%>% replace_na(0)
  
  coverage_steward  <- coverage_steward %>%
    mutate(Ogsi_Egsi = Ogsi/Egsi) 
  
  coverage <- left_join(coverage,coverage_steward,by = c("country","hbwid","year"))
  coverage <- left_join(coverage,grid_national_data_summary,by = c("country","hbwid","year"))
  
  return(coverage)
}


find_grid_coverage <- function(occ_data){
  
  # find number of species observed in each grid cell
  grid.observed <- occ_data %>% 
    group_by(hbwid,year) %>% 
    summarise(Ogi = n_distinct(scientificname))
  
  grid.expected <- grid_gadm_ranges %>% 
    group_by(hbwid) %>%
    summarise(Egi = n_distinct(scientificname))
  
  grid.expected.expanded <- grid.expected %>% 
    tidyr::expand(nesting(hbwid,Egi),year = year_start:year_end)
  
  coverage <- dplyr::left_join(grid.expected.expanded,grid.observed,by = c("hbwid","year")) 
  
  coverage$Ogi <- coverage$Ogi%>% replace_na(0)
  coverage <- coverage %>%
    mutate(Ogi_Egi = Ogi/Egi) 
  
  coverage <- left_join(coverage,grid_data_summary,by = c("hbwid","year"))
  
  return(coverage)
}



##################################################
### observations
##################################################

if (taxa_name == "amphibians"){
  file_path <- gbif_file_path
  setwd(file_path)
  files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
  
  print("reading in GBIF observations:")
  start <- Sys.time()
  gbif = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
  end <- Sys.time()
  print("reading in GBIF observations:")
  print(end - start)
  print(paste0("number of GBIF records: ",nrow(gbif)/1000000,"M"))
  
  pts_raw <- gbif
  
  print("prep GBIF observations...")
  pts <- prep_occurrence_data(gbif)
}


if (taxa_name == "birds"){
  
  file_path <- gbif_file_path
  # read in files
  setwd(file_path)
  files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
  
  print("reading in GBIF observations:")
  start <- Sys.time()
  gbif = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
  end <- Sys.time()
  print("reading in GBIF observations:")
  print(end - start)
  print(paste0("number of GBIF records: ",nrow(gbif)/1000000,"M"))
  
  print("prep GBIF observations...")
  gbif_clean <- prep_occurrence_data(gbif)
  
  # ebird data
  file_path <- ebird_file_path
  setwd(file_path)
  files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
  
  print("reading in eBird observations:")
  start <- Sys.time()
  ebird = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
  end <- Sys.time()
  print("reading in eBird observations:")
  print(end - start)
  print(paste0("number of eBird records: ",nrow(ebird)/1000000,"M"))
  
  print("prep eBird observations...")
  ebird_clean <- prep_occurrence_data(ebird)

  print("combining datasets...")
  pts <- rbind(gbif_clean,ebird_clean)

  #gbif <- gbif %>% select(scientificname,latitude,longitude,eventDate,geohash,year)
  #ebird <- ebird %>% select(scientificname,geohash,year)
  
  colnames(gbif) <- tolower(colnames(gbif))
  colnames(ebird) <- tolower(colnames(ebird))
  
  pts_raw <- rbind(gbif,ebird)
}

if (taxa_name == "mammals"){
  file_path <- gbif_file_path
  setwd(file_path)
  files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
  
  print("reading in GBIF observations:")
  start <- Sys.time()
  gbif = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
  end <- Sys.time()
  print("reading in GBIF observations:")
  print(end - start)
  print(paste0("number of GBIF records: ",nrow(gbif)/1000000,"M"))
  
  pts_raw <- gbif

  print("prep GBIF observations...")
  pts <- prep_occurrence_data(gbif)
  
  print(paste("total number of GBIF records:",nrow(gbif)))
  print(paste("total number of GBIF records used:",nrow(pts)))

}

if (taxa_name == "reptiles"){
  file_path <- gbif_file_path
  setwd(file_path)
  files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
  
  print("reading in GBIF observations:")
  start <- Sys.time()
  gbif = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
  end <- Sys.time()
  print("reading in GBIF observations:")
  print(end - start)
  print(paste0("number of GBIF records: ",nrow(gbif)/1000000,"M"))
  
  pts_raw <- gbif 
  
  print("prep GBIF observations...")
  pts <- prep_occurrence_data(gbif)
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
}