# get species x 360 grid intersection
get_intersection <- function(taxa_name){
  if (taxa_name == "amphibians"){
    grid.ranges.df <- read.csv(file.path(.wd,"geohash_grid_range_join/amphibians_360grid_join.csv"),stringsAsFactors = FALSE)
    grid_ranges <- rename(grid.ranges.df,"hbwid" = "geom_id")
    
    grid_ranges = dplyr::left_join(grid_ranges,synlist,by=c("scientificname"="Synonym")) %>% 
      filter(!is.na(Accepted)) %>% 
      select(hbwid,Accepted) %>%
      rename("scientificname" = "Accepted") 
  }
  
  if (taxa_name == "birds"){
    #grid.ranges.df <- read.csv(file.path(.wd,"geohash_grid_range_join/birds_360grid_join.csv"),stringsAsFactors = FALSE)
    grid.ranges.df <- read.csv(file.path(.wd,"projects/data-coverage/data/range-intersections/birds-360gridv2/birds_360grid.csv"),stringsAsFactors = FALSE)
    
    grid_ranges <- grid.ranges.df %>%
      filter(season %in% c(1,2))
    
    grid_ranges = dplyr::left_join(grid_ranges,synlist,by=c("sciname"="Synonym")) %>% 
      filter(!is.na(Accepted)) %>% 
      select(ID_360,Accepted) %>%
      rename("scientificname" = "Accepted",
             "hbwid" = "ID_360") 
  }
  
  if (taxa_name == "mammals"){
    #grid.ranges.df <- read.csv(file.path(.wd,"geohash_grid_range_join/mammals_360grid_join.csv"),stringsAsFactors = FALSE)
    #grid_ranges <- rename(grid.ranges.df,"hbwid" = "geom_id")
    
    # combine MDD mammals x 360 grid V2 intersections
    file_path <- "/gpfs/loomis/pi/jetz/data/species_datasets/rangemaps/mammals/mdd_mammals/grid_intersections/360gridV2/by_species/"
  
    message("reading in intersections...")
    setwd(file_path)
    files <- list.files(file_path,pattern = "*.csv",full.names = FALSE)
    
    grid_ranges = data.table::rbindlist(lapply(files, data.table::fread), fill = TRUE)
    
    grid_ranges <- grid_ranges %>%
      select(sciname, ID_360) %>%
      rename(scientificname = sciname,
             hbwid = ID_360)
    
    message("harmonizing intersections...")
    grid_ranges = dplyr::left_join(grid_ranges,synlist,by=c("scientificname"="Synonym")) %>% 
      filter(!is.na(Accepted)) %>% 
      select(hbwid,Accepted) %>%
      rename("scientificname" = "Accepted") 
  }
  
  if (taxa_name == "reptiles"){
    grid.ranges.df <- read.csv(file.path(.wd,"geohash_grid_range_join/gard_reptiles_360grid_join.csv"),stringsAsFactors = FALSE)
    grid_ranges <- rename(grid.ranges.df,"hbwid" = "geom_id")
    
    grid_ranges = dplyr::left_join(grid_ranges,synlist,by=c("scientificname"="Synonym")) %>% 
      filter(!is.na(Accepted)) %>% 
      select(hbwid,Accepted) %>%
      rename("scientificname" = "Accepted") 
  }
  return(grid_ranges)
}

