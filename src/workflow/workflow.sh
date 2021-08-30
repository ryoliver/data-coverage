#!/bin/bash
chmod +x ~/Documents/Yale/projects/data-coverage/src/workflow/workflow.sh

#-- parameters
wd=~/Documents/Yale/projects/data-coverage
src=~/Documents/Yale/projects/data-coverage/src

cd $wd

chmod 744 $src/poc/find_coverage.r #Use to make executable

$src/poc/find_coverage.r birds 1950 2019
