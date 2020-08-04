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

JOBID=$(($PBS_ARRAY_INDEX-1))

#### Constants

WORK_ROOT=/work/n02/n02/lowe/UDARA/

SCENARIOS=( 'run_15km_dom_wrf_may2010' 'run_15km_dom_wrf_may2015' \
			'run_15km_dom_wrf_sept2010' 'run_15km_dom_wrf_sept2015' )

#SCEN_NUM=1 #${#SCENARIOS[@]}
# see below for $scen - replaces $SCEN_STRING

JOB_CORES='324'
NODE_CORES='24'

FINISHED=0

#### Functions

determine_next_date () {
	next_year=$( date -d "$curr_year$curr_month$curr_day + 1 day" +%Y )
	next_month=$( date -d "$curr_year$curr_month$curr_day + 1 day" +%m )
	next_day=$( date -d "$curr_year$curr_month$curr_day + 1 day" +%d )
}

increment_dates () {
	curr_year=$next_year
	curr_month=$next_month
	curr_day=$next_day
	determine_next_date
}

#### Main

## set the scenario working directory
scen=${SCENARIOS[$JOBID]}

# start all model runs (running as a background jobs)
cd ${WORK_ROOT}$scen
aprun -n $JOB_CORES -N $NODE_CORES ./wrf.exe 2>&1 | tee WRF.log &



# get the start dates for the run
curr_year=$( grep start_year namelist.input | sed -n "s/^.*=\s*\([0-9]*\).*$/\1/p" )
curr_month=$( grep start_month namelist.input | sed -n "s/^.*=\s*\([0-9]*\).*$/\1/p" )
curr_day=$( grep start_day namelist.input | sed -n "s/^.*=\s*\([0-9]*\).*$/\1/p" )

determine_next_date

echo "starting year, month, day are: "$curr_year" "$curr_month" "$curr_day
echo "next year, month, day are: "$next_year" "$next_month" "$next_day


while [[ $FINISHED -ne $SCEN_NUM ]]; do
	# wait for some model progress
		
	sleep 300

	FINISHED=0
	NEXT_OUTPUT=0
	
	
	
	# tally up finished & next output counts
		
	RSL_TAIL=$( tail -1 rsl.error.0000 2>&1 )
	# check for successful completion
	if [[ $RSL_TAIL == *"SUCCESS"* ]]; then
		let FINISHED+=1
	fi
	
	# list wrfout files that have been written, select last one, and record the day
	model_day=$( grep "Writing wrfout" rsl.error.0000 | tail -1 | sed -n "s/^.*-\([0-9]*\)_.*$/\1/p" )
	
	# check to see if this is the next day
	if [[ $next_day == $model_day ]]; then
		let NEXT_OUTPUT+=1
	fi
		


	# submit the next processing job and increment dates, if needed
	if [[ $NEXT_OUTPUT -eq $SCEN_NUM ]]; then
		
		cd $PBS_O_WORKDIR
		
		# setup submission script
		sed -e "s|%%SCENNUM%%|${JOBID}|g" \
			-e "s|%%YEAR%%|${curr_year}|g" \
			-e "s|%%MONTH%%|${curr_month}|g" \
			-e "s|%%DAY%%|${curr_day}|g" \
			-e "s|%%SCEN%%|${scen}}|g" \
			gather_outputs_template.sh > gather_outputs_${scen}_${curr_year}_${curr_month}_${curr_day}.sh

		# try to submit the script, if this fails then wait 5 minutes before trying again
		SUBMITTED=0
		while [[ $SUBMITTED -eq 0 ]]; do
			JOBRESULT=$(qsub gather_outputs_${scen}_${curr_year}_${curr_month}_${curr_day}.sh || echo "error")
			if [[ $JOBRESULT == "error" ]]; then
				echo "serial processing script didn't submit, waiting for space in the queue"
				sleep 300
			else
				SUBMITTED=1
			fi
		done
		
		# increment the dates that we are looking for next
		increment_dates
		
		echo "submitted output processing scripts"
		echo "next year, month, day are: "$next_year" "$next_month" "$next_day
		
		cd -
		
	fi
done

echo "successfully(?) finished running WRF"

# make sure that our script waits at the end, for all sub-processes to finish
wait
