prep_taxonomy <- function(taxa_name){
  
  if(taxa_name == "amphibians"){
    synlist_file <- paste0(synlist_dir,"Amphibians_20191210.csv")
    synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
  }
  
  if(taxa_name == "birds"){
    #synlist_file <- paste0(synlist_dir,"Birds_20191204.csv")
    synlist_file <- paste0(synlist_dir,"MOL-lists/MOL_AvesTaxonomy_v2.2_Complete.csv")
    
    synlist <- convert_synlist(synlist_file) %>% 
      filter(U.or.A == "U") %>% # filter out ambiguous name matches
      select(Synonym, Accepted)
    
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
                                                  "Turdus nudigenis")) 
    synlist_MOL <- rbind(synlist,syns_birds_manual)
    
    synlist_WI <- fread(paste0(synlist_dir, "WI-lists/Birds_WI_to_MOL_harmonized_20220725.csv")) %>%
      select(sp_binomial, Accepted_MOL) %>%
      rename(Accepted = Accepted_MOL,
             Synonym = sp_binomial)
    
    synlist <- rbind(synlist_MOL, synlist_WI) %>%
      filter(!is.na(Accepted))
  }
  
  if(taxa_name == "mammals"){
    #synlist_file <- paste0(synlist_dir,"Mammal_20191204.csv")
    
    #synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
    
    synlist_MOL <- fread(paste0(synlist_dir, "MOL-lists/MOL_MammaliaTaxonomy_v2.2_LF.csv")) %>%
      select(Accepted, Synonym)
    
    synlist_MOL_adapted <- synlist_MOL %>%
      separate(Synonym, c("a", "b", "c")) %>%
      unite("Synonym", a:b, sep = " ") %>%
      select(Accepted, Synonym) %>%
      distinct(Accepted, Synonym)
    
    synlist_WI <- fread(paste0(synlist_dir, "WI-lists/Mammals_WI_to_MOL_harmonized_20220725.csv")) %>%
      select(sp_binomial, Accepted_MOL) %>%
      rename(Accepted = Accepted_MOL,
             Synonym = sp_binomial)
    
    synlist <- rbind(synlist_MOL, synlist_MOL_adapted, synlist_WI) %>%
      filter(!is.na(Accepted))
  }
  
  if(taxa_name == "reptiles"){
    synlist_file <- paste0(synlist_dir,"Reptile_20191211.csv")
    synlist <- convert_synlist(synlist_file) %>% filter(U.or.A == "U") # filter out ambiguous name matches
  }
  return(synlist)
}

