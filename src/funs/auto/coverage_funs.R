### functions for finding data coverage

## national level coverage
# ssii1 = national coverage (species-focal)
# ssii2 = national coverage (assemblage-focal)
# ssii3 = steward's coverage (species-focal)
# ssii4 = steward's coverage (assemblage-focal)

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
    mutate(n_records = ifelse(is.na(n_records),0,n_records))
  
  # write out species level coverage within nations
  fwrite(country.species,paste0(.outPF,.taxa_name,"_species_national_coverage_",.data_source,".csv"))
  
  # find national coverage values
  coverage <- country.species %>% 
    group_by(country,year) %>% 
    summarise(ssii1 = mean(Oci_Eci,na.rm=TRUE), 
              ssii2 = sum(Oci/sum(Eci,na.rm=TRUE),na.rm=TRUE),
              ssii3 = sum(Oci_Eci*(Eci_Eki/Ecl_Ekl),na.rm=TRUE),
              ssii4 = sum(Oci*Eci_Eki/sum(Eci*Eci_Eki,na.rm = TRUE),na.rm = TRUE),
              n_records = sum(n_records)) 
  
  return(coverage)
}

## species level coverage
# Eki = number of expected grid cells
# Oi = number of observed grid cells
# ssii = data coverage
# n_records = total number of records

find_species_coverage <- function(occ_data){
  # find number of grid cells of observed occurrence for each species in each country
  observed <- occ_data %>% 
    group_by(scientificname,year) %>% 
    distinct(hbwid,.keep_all=TRUE) %>% 
    summarise(Oi = sum(prop_grid_country))
  
  expected <- expected %>% 
    ungroup(country) %>% 
    select(scientificname,year,Eki) %>%
    expand(nesting(scientificname,Eki),year = .year_start:.year_end) %>%
    distinct(scientificname, year, .keep_all = TRUE)
  
  species <- dplyr::left_join(expected,observed,by = c("scientificname","year"))
  species$Oi <- species$Oi %>% replace_na(0)
  
  # find proportion of # of grid cells with observations to # of grid cells with expected occurrence for each species
  species <- species %>% 
    dplyr::mutate(ssii = Oi/Eki)
  
  # join with species data summary
  species <- left_join(species,species_data_summary, by = c("scientificname","year"))
  
  species <- species %>%
    mutate(n_records = ifelse(is.na(n_records),0,n_records)) 
  
  return(species)
}

## grid level coverage (separating grid cells by country)
# Egi = number of expected species
# Ogi = number of observed species
# ssii2 = data coverage
# Egsi = number of expected species
# Ogsi = number of observed species
# ssii4 = data coverage weighted by stewardship
# n_records = total number of records

find_grid_national_coverage <- function(occ_data){
  
  # find number of species observed in each grid cell
  grid.observed <- occ_data %>% 
    group_by(country,hbwid,year) %>% 
    summarise(Ogi = n_distinct(scientificname))
  
  coverage <- dplyr::left_join(grid.expected.expanded,grid.observed,by = c("country","hbwid","year")) 
  
  coverage$Ogi <- coverage$Ogi%>% replace_na(0)
  
  coverage <- coverage %>%
    mutate(ssii2 = Ogi/Egi) 
  
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
    expand(nesting(hbwid,country,Egsi),year = .year_start:.year_end)
  
  
  coverage_steward <- left_join(expected.grid,observed,by = c("country","hbwid","year"))
  coverage_steward$Ogsi <- coverage_steward$Ogsi%>% replace_na(0)
  
  coverage_steward  <- coverage_steward %>%
    mutate(ssii4 = Ogsi/Egsi) 
  
  coverage <- left_join(coverage,coverage_steward,by = c("country","hbwid","year"))
  coverage <- left_join(coverage,grid_national_data_summary,by = c("country","hbwid","year"))
  
  return(coverage)
}

## grid level coverage 
# Egi = number of expected species
# Ogi = number of observed species
# ssii = data coverage
# n_records = total number of records

find_grid_coverage <- function(occ_data){
  
  # find number of species observed in each grid cell
  grid.observed <- occ_data %>% 
    group_by(hbwid,year) %>% 
    summarise(Ogi = n_distinct(scientificname))
  
  grid.expected <- grid_gadm_ranges %>% 
    group_by(hbwid) %>%
    summarise(Egi = n_distinct(scientificname))
  
  grid.expected.expanded <- grid.expected %>% 
    tidyr::expand(nesting(hbwid,Egi),year = .year_start:.year_end)
  
  coverage <- dplyr::left_join(grid.expected.expanded,grid.observed,by = c("hbwid","year")) 
  
  coverage$Ogi <- coverage$Ogi%>% replace_na(0)
  coverage <- coverage %>%
    mutate(ssii = Ogi/Egi) 
  
  coverage <- left_join(coverage,grid_data_summary,by = c("hbwid","year"))
  
  return(coverage)
}
