#!/bin/bash
chmod +x /gpfs/ysm/project/jetz/ryo3/projects/data-coverage/src/workflow/workflow.sh

#-- parameters
#wd=/gpfs/ysm/project/jetz/ryo3/projects/data-coverage
src=/gpfs/ysm/project/jetz/ryo3/projects/data-coverage/src

#cd $wd

#make executable
chmod +x $src/workflow/run_intersection.sh
#chmod 744 $src/poc/find_coverage.r
#chmod 744 $src/poc/intersect_360grid_gadm.r

#run intersection between 360 grid and GADM
sbatch $src/workflow/run_intersection.sh

#find covearge
#$src/poc/find_coverage.r birds 1950 2019
