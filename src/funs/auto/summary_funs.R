### functions for summarizing number of data records

# number of records per species in each country
summarize_species_national_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(country,scientificname,year) %>%
    summarise("n_records" = n())
  return(summary)
}

# number of records per species
summarize_species_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(scientificname,year) %>%
    summarise("n_records" = n())
  return(summary)
}

# number of records per species in each grid cell considering national boundaries
summarize_species_grid_national_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(country,hbwid,scientificname,year) %>%
    summarise("n_records" = n())
  return(summary)
}

# number of records per grid cell considering national boundaries
summarize_grid_national_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(country,hbwid,year) %>%
    summarise("n_records" = n())
  return(summary)
}

# number of records per grid cell
summarize_grid_data <- function(occ_data){
  summary <- occ_data %>%
    group_by(hbwid,year) %>%
    summarise("n_records" = n())
  return(summary)
}
