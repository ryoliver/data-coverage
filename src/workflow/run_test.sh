#!/bin/bash

#SBATCH --job-name=test
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ruth.oliver@yale.edu
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=1000G -t 2-
#SBATCH --partition=general,bigmem,pi_jetz
#SBATCH -C avx2

module load R

Rscript /gpfs/ysm/project/jetz/ryo3/projects/data-coverage/src/poc/test_file_read.R $1 $2 $3 $4