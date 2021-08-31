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