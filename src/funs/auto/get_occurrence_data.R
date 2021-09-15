get_occurrence_data <- function(file_path){
  setwd(file_path)
  files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
  
  pts_raw = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
  colnames(pts_raw) <- tolower(colnames(pts_raw))
  
  if(file_path == wi_file_path){
    library(geohashTools)
    
    pts_raw$geohash <- gh_encode(pts_raw$latitude,pts_raw$longitude,precision = 5)
    pts_raw$eventdate <- as.Date(rep(NA,nrow(pts_raw)))
    
    pts_raw <- pts_raw %>%
      rename("scientificname" = sp_binomial,
             "year" = photo_year) %>%
      select(scientificname,latitude,longitude,eventdate,year,geohash)
  }
  return(pts_raw)
}