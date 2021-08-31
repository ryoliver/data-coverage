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
    grid.ranges.df <- read.csv(file.path(.wd,"geohash_grid_range_join/birds_360grid_join.csv"),stringsAsFactors = FALSE)
    grid_ranges <- grid.ranges.df %>%
      filter(seasonality %in% c(1,2))
    
    grid_ranges = dplyr::left_join(grid_ranges,synlist,by=c("scientificname"="Synonym")) %>% 
      filter(!is.na(Accepted)) %>% 
      select(hbwid,Accepted) %>%
      rename("scientificname" = "Accepted") 
  }
  
  if (taxa_name == "mammals"){
    grid.ranges.df <- read.csv(file.path(.wd,"geohash_grid_range_join/mammals_360grid_join.csv"),stringsAsFactors = FALSE)
    grid_ranges <- rename(grid.ranges.df,"hbwid" = "geom_id")
    
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

