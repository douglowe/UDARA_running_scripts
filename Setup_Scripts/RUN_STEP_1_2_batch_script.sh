#!/bin/bash

#
#  Script for running Steps 1 & 2 of the running directory setup
#    for a list of scenarios (automating the command line actions).
#

# select global settings file, and load it
GLOBAL_SETTINGS_FILE=/work/n02/n02/lowe/UDARA/UDARA_running_scripts/Setup_Scripts/local_settings.txt

source $GLOBAL_SETTINGS_FILE

SCENARIOS=( 'may2010' 'may2015' 'sept2010' 'sept2015' )

### imported from global settings file:
#
# WORK_ROOT=/work/n02/n02/lowe/PROMOTE/
#
# SCRIPT_ROOT=/work/n02/n02/lowe/PROMOTE/running_scripts/

for scen in ${SCENARIOS[@]}; do

	echo "creating run directory, and setting chemical details for scenario: "${scen}

	scen_dir=run_15km_dom_wrf_${scen}

	work_dir=${WORK_ROOT}${scen_dir}

	${SCRIPT_ROOT}STEP1_create_run_dir.sh ${GLOBAL_SETTINGS_FILE} ${work_dir} ${scen}

done

