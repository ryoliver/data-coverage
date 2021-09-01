#!/bin/bash

#SBATCH --job-name=intersect
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ruth.oliver@yale.edu
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=100g -t 2-
#SBATCH --partition=general,bigmem,pi_jetz
#SBATCH -C avx2

module load R

Rscript /home/ryo3/project/projects/data-coverage/src/poc/intersect_360grid_gadm.R /gpfs/ysm/scratch60/jetz/ryo3/coverage_output
