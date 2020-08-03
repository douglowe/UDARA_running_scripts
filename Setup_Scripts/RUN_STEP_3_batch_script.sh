#!/bin/bash

#
#  Script for running Step 3 of the running directory setup
#    for a list of scenarios (automating the command line actions).
#

# select global settings file, and load it
GLOBAL_SETTINGS_FILE=/work/n02/n02/lowe/UDARA/UDARA_running_scripts/Setup_Scripts/local_settings.txt

source $GLOBAL_SETTINGS_FILE


SCENARIOS=( 'may2010' 'may2015' 'sept2010' 'sept2015' )


time_settings_tail="_start.txt"

for scen in ${SCENARIOS[@]}; do

	echo "(re)setting time period specific details for scenario: "${scen}

	time_settings=${scen}${time_settings_tail}

	scen_dir=run_15km_dom_wrf_${scen}

	work_dir=${WORK_ROOT}${scen_dir}

	${SCRIPT_ROOT}STEP3_timeperiod_setup.sh ${GLOBAL_SETTINGS_FILE} ${work_dir} ${time_settings}

done

