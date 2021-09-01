prep_taxonomy <- function(taxa_name){
  # synonym list directory/file names
  synlist_dir <- "/home/ryo3/scratch60/synonym-lists/"
  
  if(taxa_name == "amphibians"){
    synlist_file <- paste0(synlist_dir,"Amphibians_20191210.csv")
    synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
  }
  
  if(taxa_name == "birds"){
    synlist_file <- paste0(synlist_dir,"Birds_20191204.csv")
    synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
    
    syns_birds_manual <- data.frame("Accepted" = c("Ardea albus",
                                                   "Ardea albus",
                                                   "Anas poecilorhyncha",
                                                   "Haliaeetus ichthyaetus",
                                                   "Butorides virescens",
                                                   "Colaptes auratus",
                                                   "Buteo rufinus",
                                                   "Psophia crepitans",
                                                   "Cinclodes fuscus",
                                                   "Hydrornis guajanus",
                                                   "Alethe diademata",
                                                   "Neomorphus squamiger",
                                                   "Psophia viridis",
                                                   "Turdus nudigenis"),
                                    "Synonym" = c("Ardea modestus",
                                                  "Ardea albus",
                                                  "Anas poecilorhyncha",
                                                  "Icthyophaga ichthyaetus",
                                                  "Butorides virescens",
                                                  "Colaptes cafer",
                                                  "Buteo rufinus",
                                                  "Psophia ochroptera",
                                                  "Cinclodes fuscus",
                                                  "Pitta guajana",
                                                  "Alethe castanea",
                                                  "Neomorphus squamiger",
                                                  "Psophia obscura",
                                                  "Turdus nudigenis")) %>%
      mutate("U.or.A" = rep("U",nrow(.)))
    synlist <- rbind(synlist,syns_birds_manual)
  }
  
  if(taxa_name == "mammals"){
    synlist_file <- paste0(synlist_dir,"Mammal_20191204.csv")
    synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
  }
  
  if(taxa_name == "reptiles"){
    synlist_file <- paste0(synlist_dir,"Reptile_20191211.csv")
    synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
  }
  return(synlist)
}

