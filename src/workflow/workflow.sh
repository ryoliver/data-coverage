#!/bin/bash
chmod +x /gpfs/ysm/project/jetz/ryo3/projects/data-coverage/src/workflow/workflow.sh

#-- parameters
#wd=/gpfs/ysm/project/jetz/ryo3/projects/data-coverage
src=/gpfs/ysm/project/jetz/ryo3/projects/data-coverage/src

#cd $wd

#make executable
chmod +x $src/workflow/run_intersection.sh
chmod +x $src/workflow/run_coverage.sh
chmod +x $src/workflow/run_coverage_large.sh

#run intersection between 360 grid and GADM
sbatch $src/workflow/run_intersection.sh

#find covearge
sbatch $src/workflow/run_coverage.sh mammals 1950 2019 202004
