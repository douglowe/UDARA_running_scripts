#!/bin/bash --login

#PBS -J 1-4
#PBS -l select=serial=true:ncpus=1
#PBS -l walltime=24:00:00
#PBS -A n02-weat
#PBS -N udara-data

#
#  script for gathering the outputs from multiple WRF runs (for PROMOTE)
#
#  it should be called after the wrf-chem array job, waiting for the array to start running
#


cd $PBS_O_WORKDIR

JOBID=(($PBS_ARRAY_INDEX-1))


# load miniconda & activate NCL virtual environment
. ~/miniconda3.sh
conda activate ncl-6.6.2


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




#### Constants
SCRIPT_DIR=/work/n02/n02/lowe/UDARA/UDARA_running_scripts/Data_Extraction_Scripts/

WORK_ROOT=/work/n02/n02/lowe/UDARA/

OUTPUT_ROOT=/work/n02/n02/lowe/UDARA/UDARA_data_outputs/


SCENARIOS=( 'run_15km_dom_wrf_may2010' 'run_15km_dom_wrf_may2015' \
			'run_15km_dom_wrf_sept2010' 'run_15km_dom_wrf_sept2015' )



## set the scenario working directory
SCENARIO=${SCENARIOS[$JOBID]}
SCEN_NUM=1

## set fixed scenario settings
DOMAINS=( 'd01' )
DOM_NUM=${#DOMAINS[@]}

SCEN_STRING="scenario=\"${SCENARIO}\""
INDIR_STRING="input_root_directory=\"${WORK_ROOT}\""
OUTDIR_STRING="output_root_directory=\"${OUTPUT_ROOT}\""



# get the start dates for the run
curr_year=$( grep start_year namelist.input | sed -n "s/^.*=\s*\([0-9]*\).*$/\1/p" )
curr_month=$( grep start_month namelist.input | sed -n "s/^.*=\s*\([0-9]*\).*$/\1/p" )
curr_day=$( grep start_day namelist.input | sed -n "s/^.*=\s*\([0-9]*\).*$/\1/p" )

determine_next_date

echo "starting year, month, day are: "$curr_year" "$curr_month" "$curr_day
echo "next year, month, day are: "$next_year" "$next_month" "$next_day






YEAR=%%YEAR%%
MONTH=%%MONTH%%
DAY=%%DAY%%

# change to the model running directory
cd ${WORK_ROOT}$SCENARIO



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
		
		cd ${SCRIPT_DIR}
		
		# settings to be passed to the ncl script
		YEAR_STRING="year=(/\"${YEAR}\"/)"
		MONTH_STRING="month=(/\"${MONTH}\"/)"
		DAY_STRING="day=(/\"${DAY}\"/)"
		HOUR_STRING='hour=(/"*"/)'

		
		# setup submission script
		sed -e "s|%%SCENNUM%%|${JOBID}|g" \
			-e "s|%%YEAR%%|${curr_year}|g" \
			-e "s|%%MONTH%%|${curr_month}|g" \
			-e "s|%%DAY%%|${curr_day}|g" \
			-e "s|%%SCEN%%|${scen}}|g" \
			gather_outputs_template.sh > gather_outputs_${scen}_${curr_year}_${curr_month}_${curr_day}.sh


		### create the storage directories (running them as background jobs)
		for dom in ${DOMAINS[@]}; do
			OUTFILE_STRING="outfile_name=\"wrfdata_${dom}_${SCENARIO}_${YEAR}_${MONTH}_${DAY}.nc\""
			DOMAIN_STRING="domain=\"${dom}\""
	
			ncl $YEAR_STRING $MONTH_STRING \
				$DAY_STRING $HOUR_STRING \
				$INDIR_STRING $OUTDIR_STRING \
				$SCEN_STRING $DOMAIN_STRING $OUTFILE_STRING \
				${SCRIPT_DIR}CREATE_data_file.ncl > log_create_${dom}_${SCENARIO}_${YEAR}_${MONTH}_${DAY}.txt &
		done

		wait

		# test to make sure we were successful
		# exit if we were not
		SUCCESS=0
		for dom in ${DOMAINS[@]}; do
			LOG_TAIL=$( tail -1 log_create_${dom}_${SCENARIO}_${YEAR}_${MONTH}_${DAY}.txt 2>&1 )
			if [[ $LOG_TAIL == *"SUCCESS"* ]]; then
				let SUCCESS+=1
			fi
		done
		if [[ SUCCESS -ne $DOM_NUM ]]; then
			echo "failed to create data files, check logs!"
			exit
		else
			echo "created data files, deleting log files"
			for dom in ${DOMAINS[@]}; do
				rm log_create_${dom}_${SCENARIO}_${YEAR}_${MONTH}_${DAY}.txt
			done
		fi

		### populate the storage directories (running them as background jobs)
		for dom in ${DOMAINS[@]}; do
			OUTFILE_STRING="outfile_name=\"wrfdata_${dom}_${SCENARIO}_${YEAR}_${MONTH}_${DAY}.nc\""
			DOMAIN_STRING="domain=\"${dom}\""
	
			ncl $YEAR_STRING $MONTH_STRING \
				$DAY_STRING $HOUR_STRING \
				$INDIR_STRING $OUTDIR_STRING \
				$SCEN_STRING $DOMAIN_STRING $OUTFILE_STRING \
				${SCRIPT_DIR}EXTRACT_SAVE_2D_data.ncl > log_extract_${dom}_${SCENARIO}_${YEAR}_${MONTH}_${DAY}.txt &
		done

		wait

		# test to make sure we were successful
		# exit if we were not
		SUCCESS=0
		for dom in ${DOMAINS[@]}; do
			LOG_TAIL=$( tail -1 log_extract_${dom}_${SCENARIO}_${YEAR}_${MONTH}_${DAY}.txt 2>&1 )
			if [[ $LOG_TAIL == *"SUCCESS"* ]]; then
				let SUCCESS+=1
			fi
		done
		if [[ SUCCESS -ne $DOM_NUM ]]; then
			echo "failed to extract data, check logs!"
			exit
		else
			echo "extracted data, deleting log files"
			for dom in ${DOMAINS[@]}; do
				rm log_extract_${dom}_${SCENARIO}_${YEAR}_${MONTH}_${DAY}.txt
			done
		fi

		wait

		# now go back and delete the old data files!!!!!
		cd ${WORK_ROOT}$SCENARIO
		rm wrfout_*_${YEAR}-${MONTH}-${DAY}_*

		
		# increment the dates that we are looking for next
		increment_dates
		
		echo "run output processing scripts"
		echo "next year, month, day are: "$next_year" "$next_month" "$next_day
		
		
	fi
	
done









#### Main









