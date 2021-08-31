#----
#---- These functions are used by breezy_script.r 
#----

#' @example 
#' t1 <- Sys.time()
#' diffmin(t1)
diffmin <- function(t,t2=Sys.time()) round(difftime(t2, t, unit = "min"),2)

