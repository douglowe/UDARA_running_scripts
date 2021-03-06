;
; 2D data extraction script
; 
; This script is for creating the storage netcdf file for 2D extracted data
;
;
; This script is set to receive optional command line inputs (with default values
;     given below if these are not provided)
;
; The optional inputs are:
;   year, month, day, hour --> strings defining data arrays containing time information
;     (format: "year = (/1997,1998/)" or "year = (/*/)" )
;   input_root_directory, output_root_directory --> strings which define these paths
;   scenario --> string defining the scenario name to use for output subdirectory
;   outfile_name --> string to use for name of the output file
;   domain --> string defining the model domain that is being processed
;
;
; The variables to be created are hard-coded in this script.
;
;




load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$WRF_NCL_ROOT/data_extraction_library.ncl"

begin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; script settings ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
root_directory = "/nerc/n02/n02/lowe/"

if (.not. isvar("input_root_directory")) then
	input_root_directory  = root_directory+"PROMOTE_data_files/Third_VBS_SOA_new_namelist_control/"
end if
if (.not. isvar("output_root_directory")) then
	output_root_directory = root_directory+"PROMOTE_data_analysis/working_space/extracted_data/"
end if

if (.not. isvar("scenario")) then
	scenario = "May_2015-MOZART_boundary_no_dust-base_SOA-BB_Anthro_VBS-x3_emissions-Aging_Rate_1e-11-OC_ratio_tracking"
end if

if (.not. isvar("outfile_name")) then
	outfile_name="test_file.nc"
end if

if (.not. isvar("domain")) then
	domain="d03"
end if

;input_root_directory  = root_directory+"UDARA_data_files/15km_mercator/"
;output_root_directory = root_directory+"UDARA_data_analysis/extracted_data/"
;scenario = "first_test"


file_variables = (/ "AOD550", "PM25_mass", "BTEX", "CO", "NOx", "O3" /)




; This flag determines if we want to plot a set of defined time points, or the whole campaign.
;    True -> plot the chosen times
;    False -> plot *all* the model data (Warning: it will take 30-50 minutes to load the data)
;    
;    Note: If you set day = "*" then you will plot the selected hour on each day.
;          If you set hour = "*" then you will plot all hours in the selected day. 
;    Note: ***These times are all UTC*** 
plot_selected_times = True
if (.not. isvar("day")) then
	day = (/"*"/)
end if
if (.not. isvar("hour")) then
	hour = (/"00"/)
end if
if (.not. isvar("month")) then
	month = (/"*"/)   ; don't change this - always use "*"
end if
if (.not. isvar("year")) then
	year  = (/"*"/)   ; don't change this - always use "*"
end if
; NOTE: When plotting "rain_hour" you should plot all model data, as this uses the differences
;       between each model output to derive the hourly rain fall.



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; variable settings ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; set the conversion factors for variables here (if required), e.g.:
;; variable_units@T2  = (/"K","C"/)
;;    First string is the original unit (e.g. K - Kelvin)
;;    Second string is the new unit (e.g. C - Celsius)
variable_units@T2  = (/"K","C"/)


;;; set the variable labels here
variable_description@AOD550      = "Total aerosol optical depth in column at 550nm."
variable_unit_description@AOD550 = ""

variable_description@PM25_mass      = "Dry PM2.5 aerosol mass"
variable_unit_description@PM25_mass = "ug/kg-dryair"

variable_description@BTEX      = "Summed benzene, toluene, and o-xylene mass"
variable_unit_description@BTEX = "ug/m3"

variable_description@CO         = "Carbon Monoxide mixing ratio"
variable_unit_description@CO    = "ppmv"

variable_description@NOx         = "NOx mixing ratio"
variable_unit_description@NOx    = "ppmv"

variable_description@O3          = "Ozone mixing ratio"
variable_unit_description@O3     = "ppmv"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; end of settings ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;





;;; check that the output directory exists, if not then create it
system("if ! test -d  "+output_root_directory+" ; then mkdir "+output_root_directory+"; fi")
system("if ! test -d  "+output_root_directory+scenario+" ; then mkdir "+output_root_directory+scenario+"; fi")



;;; open the data files, which we need for copying domain information
Dfiles = create_input_file_list(plot_selected_times,domain,year,month,day,hour,input_root_directory+scenario)
;Dfiles = create_input_file_list(plot_selected_times,domain,year,month,day,hour,input_root_directory)
check_file_status(Dfiles)  
DATA_FILES = addfiles(Dfiles+".nc","r")

;;; create the output file
create_output_file(DATA_FILES,output_root_directory+scenario,outfile_name,file_variables)

print("SUCCESS: finished creating the data file")

end
