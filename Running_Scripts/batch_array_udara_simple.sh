#!/bin/bash --login

#PBS -J 1-4
#PBS -r y
#PBS -l select=14
#PBS -l walltime=06:00:00
#PBS -A n02-weat
#PBS -N udara-batch

#
#  script for running WRF, and gathering the outputs that we require
#
#  this should be run: qsub STEP4_run_WRF_gather_outputs.sh
#
#  
#

cd $PBS_O_WORKDIR

JOBID=(($PBS_ARRAY_INDEX-1))

#### Constants

WORK_ROOT=/work/n02/n02/lowe/UDARA/

SCENARIOS=( 'run_15km_dom_wrf_may2010' 'run_15km_dom_wrf_may2015' \
			'run_15km_dom_wrf_sept2010' 'run_15km_dom_wrf_sept2015' )

#SCEN_NUM=1 #${#SCENARIOS[@]}
# see below for $scen - replaces $SCEN_STRING

JOB_CORES='324'
NODE_CORES='24'


#### Main

## set the scenario working directory
scen=${SCENARIOS[$JOBID]}

# start all model runs (running as a background jobs)
cd ${WORK_ROOT}$scen
aprun -n $JOB_CORES -N $NODE_CORES ./wrf.exe 2>&1 | tee WRF.log


echo "successfully(?) finished running WRF"

# make sure that our script waits at the end, for all sub-processes to finish
wait
