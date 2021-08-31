# function to convert double list format synonym lists

convert_synlist <- function(file_name){
  synlist <- fread(file_name)
  
  names(synlist) <- tolower(names(synlist))
  
  accepted <- synlist %>% filter(accid == 0)
  synonym <- synlist %>% filter(accid > 0)
  accepted_dup <- accepted
  accepted_dup$accid <- accepted_dup$id
  syns_all <- rbind(synonym,accepted_dup)
  
  synlist <- left_join(accepted,syns_all,by=c("id" = "accid")) 
  
  synlist <- synlist %>%
    select(canonical.x,canonical.y) %>%
    rename("Accepted" = canonical.x, "Synonym" = canonical.y) %>%
    distinct(Accepted,Synonym) %>% 
    group_by(Synonym) %>%
    mutate("U.or.A" = if_else(n() == 1, "U","A")) %>%
    ungroup()
  
  return(synlist)
}

