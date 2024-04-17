# data coverage workflow

#### Species Status Information Index (SSII) and Species Sampling Effectiveness Index (SSEI)

General workflow for assessing data coverage based on methodology established in Oliver et al. 2021. 
Original workflow from Oliver et al. 2021 at https://github.com/ryoliver/oliver-etal-2021

> Oliver, R. Y., Meyer, C., Ranipeta, A., Winner, K., & Jetz, W. (2021). _Global and national trends, gaps, and opportunities in documenting and monitoring species distributions_. PLoS Biology 19(8): e3001336. doi.org/10.1371/journal.pbio.3001336


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
  
