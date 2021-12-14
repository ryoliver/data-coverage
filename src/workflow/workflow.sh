#!/bin/bash
chmod +x /gpfs/ysm/project/jetz/ryo3/projects/data-coverage/src/workflow/workflow.sh

#-- parameters
src=/gpfs/ysm/project/jetz/ryo3/projects/data-coverage/src

#make executable
chmod +x $src/workflow/run_intersection.sh
chmod +x $src/workflow/run_coverage.sh
chmod +x $src/workflow/run_coverage_large.sh
chmod +x $src/workflow/run_test.sh

#run intersection between 360 grid and GADM
FILE=/gpfs/ysm/project/jetz/ryo3/projects/data-coverage/analysis/intersection-gadm-360grid.csv
if [ -f "$FILE" ]; then
  echo "intersection already exists";
else
  echo "run intersection"
  sbatch $src/workflow/run_intersection.sh
fi


#find covearge
#sbatch $src/workflow/run_coverage.sh mammals 1950 2019 gbif-wi
#sbatch $src/workflow/run_coverage.sh mammals 1950 2019 gbif
sbatch $src/workflow/run_coverage.sh mammals 1950 2019 wi


#sbatch $src/workflow/run_coverage_large.sh birds 1950 2019 gbif-wi
#sbatch $src/workflow/run_coverage_large.sh birds 1950 2019 gbif

#sbatch $src/workflow/run_test.sh birds 1950 2019 gbif


