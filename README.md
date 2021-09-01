# data coverage workflow

#### Species Status Information Index (SSII) and Species Sampling Effectiveness Index (SSEI)

General workflow for assessing data coverage based on methodology established in Oliver et al. 2021. 
Original workflow from Oliver et al. 2021 at https://github.com/ryoliver/oliver-etal-2021

> Oliver, R. Y., Meyer, C., Ranipeta, A., Winner, K., & Jetz, W. (2021). _Global and national trends, gaps, and opportunities in documenting and monitoring species distributions_. PLoS Biology 19(8): e3001336. doi.org/10.1371/journal.pbio.3001336


## goals:
Rework coverage workflow to support wider applications
* establish core functions
* create better flexibility for occurrence datasets
* support wider taxonomic and geographic scope
* generate output which stores metadata

## to do:
* separate functions from main script
* check file paths/variable names
* debug WI issue

## activity log:

|date|activity|
|:-|:------------|
|2021-08-30|create repo|
||start coverage scripts|
|2021-08-31|set up repo on farnam|
||extract functions from main script|
|2021-09-01|extracted functions from main script|
||extracted 360 grid x GADM interesection|
||updated workflow script|
||running intersection|


## notes
* does the 360 grid x GADM intersection need to happen in each run?
