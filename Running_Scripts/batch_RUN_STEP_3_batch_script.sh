#!/bin/bash --login
#
#PBS -l select=serial=true:ncpus=1
#PBS -l walltime=00:20:00
#PBS -A n02-weat


cd ${PBS_O_WORKDIR}


#
#  Script for running Step 3 of the running directory setup
#    for a list of scenarios (automating the command line actions).
#

# select global settings file, and load it
GLOBAL_SETTINGS_FILE=/work/n02/n02/lowe/PROMOTE/running_scripts_test_scenarios/local_settings.txt

source $GLOBAL_SETTINGS_FILE


SCENARIOS=( 'run_WRF_test_base' )

#WORK_ROOT=/work/n02/n02/lowe/PROMOTE/

#SCRIPT_ROOT=/work/n02/n02/lowe/PROMOTE/running_scripts/

time_settings="time_prototype_may_3.txt"

for scen in ${SCENARIOS[@]}; do

	echo "(re)setting time period specific details for scenario: "${scen}

	work_dir=${WORK_ROOT}${scen}

	${SCRIPT_ROOT}STEP3_timeperiod_setup.sh ${GLOBAL_SETTINGS_FILE} ${work_dir} ${time_settings}

done

