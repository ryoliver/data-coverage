get_occurrence_data <- function(file_path){
  setwd(file_path)
  files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
  
  pts_raw = data.table::rbindlist(lapply(files, data.table::fread),use.names = TRUE)
  colnames(pts_raw) <- tolower(colnames(pts_raw))
  return(pts_raw)
}