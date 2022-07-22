get_occurrence_data <- function(file_path){
  
  if (file_path != wi_file_path) {
    setwd(file_path)
    files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
    
    message("reading in files...")
    pts_raw = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
    message(paste0("n records: ", nrow(pts_raw)))
  }
  
  if (file_path == wi_file_path) {
    message("reading in files...")
    pts_raw = fread(paste0(wi_file_path,"WI_data_coverage_20220530.csv"))
    }
  
  message("check column names...")
  colnames(pts_raw) <- tolower(colnames(pts_raw))
  
  #message("check data format...")
  #pts_raw$eventdate <- as.character(pts_raw$eventdate)
  
  if(file_path == wi_file_path){
    library(geohashTools)
    
    pts_raw$geohash <- gh_encode(pts_raw$latitude,pts_raw$longitude,precision = 5)
    #pts_raw$eventdate <- as.character(rep(NA,nrow(pts_raw)))
    
    pts_raw <- pts_raw %>%
      rename("scientificname" = sp_binomial) 
      #select(scientificname,latitude,longitude,eventdate,year,geohash)
  }
  
  pts_raw <- pts_raw %>%
    select(scientificname, year, geohash)
  
  return(pts_raw)
}