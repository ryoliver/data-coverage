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
* sort out issue with birds -- just memory?

## workflow overview
* **workflow.sh**- controls entire workflow
  * **run_intersection.sh**- batch job file for 360 grid x GADM intersection
    * runs **intersect_360grid_gadm.R**
      * intersects 360 grid with GADM based on geohashes and saves output
  * **run_coverage.sh** - batch job file for running coverage
    * runs **find_coverage.R**
  * **run_coverage_large.sh** - batch job for larger coverage runs
* **find_coverage.R** - primary script for running coverage
  * **prep_taxonomy.R** - converts synonym list format
  * **get_intersection.R** - pulls intersection between 360 grid and expert ranges
  * **get_occurrence_data.R** - pull point occurrence data
  * **summary_funs.R** - functions for summarizing data records at different resolutions
  * **coverage_funs.R** - functions for computing coverage
  

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
|2021-09-02|fixed bug in intersection|
||reran intersection|
||updated coverage workflow|
||tested running coverage|
|2021-09-13|fixed bug in intersection|
||save off candidate geohashes|
||fixed hidden variable bugs|
||successful run!|
|2021-09-15|added flexibility for different point datasets|
||moved wi data prep to workflow|
||test run on gbif+wi for mammals|
||debugged issue joining gbif + wi|
||submitted run to test|
|2021-09-16|successful run for mammals|
||memory issue for birds|
||need to look at output|
|2021-09-17|issue running birds|
||still debugging...|
|2021-10-12|trying to rerun birds|
|2021-10-13|still debugging birds...|
||seems like data read in works in main script|
|2021-10-14|looks like the issue is with changing date format|






