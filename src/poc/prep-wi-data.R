rm(list=ls())
require(dplyr)
library(data.table)
library(tidyverse)
library(Hmisc) 
library(geohashTools)


data_dir <- "/gpfs/ysm/project/jetz/ryo3/wi-data/"
wi <- fread(paste0(data_dir,"input-files/WI_coverage_cleaned_version_from_science_vw_wild_animals_03042021.csv")) %>%
  rename("scientificname" = sp_binomial,
         "year" = photo_year) 



wi$geohash <- gh_encode(wi$latitude,wi$longitude,precision = 5)

wi <- wi %>%
  select(scientificname,year,geohash)

fwrite(wi,paste0(data_dir,"output-files/wi-data-cleaned.csv"))
