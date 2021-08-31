
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
