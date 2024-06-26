#!/bin/bash

#SBATCH --job-name=coverage_large
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ruth.oliver@yale.edu
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=1000G -t 2-
#SBATCH --partition=general,bigmem,pi_jetz
#SBATCH -C avx2

#module load R/3.6.1-foss-2018b
module load R/4.1.0-foss-2020b

Rscript /gpfs/ysm/project/jetz/ryo3/projects/data-coverage/src/poc/find_coverage.R $1 $2 $3 $4
