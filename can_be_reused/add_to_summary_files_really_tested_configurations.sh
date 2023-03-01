#!/usr/bin/bash

# this script takes as input a result folder coming from automatisation 
# The first function add column to summary files that contains the real configuration realized by the automatization script . 
# We remembered that in some phones as google pixel 
# it is not possible to set different values of frequency on cores present on the same socket. 
# The consequence is that the configuration presented in the first column in the summary
# is not the one that have been  realy tested by the script

# This is wy we add some column in the summary file containing the configuration really tested.   


AUTOMATIZATION_PROJECT_PATH="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization"
PROJECT_TRASH_FOLDER="${AUTOMATIZATION_PROJECT_PATH}/can_be_reused/old_tools/trash"
summary_files_only_folder="${AUTOMATIZATION_PROJECT_PATH}/summary_files_only"
AUTOMATIZATION_PROJECT_PATH_WINDOWS_SYNTAX="C:\Users\lavoi\opportunist_task_on_android\scripts_valuable_files\experiment_automatization"
reduce_moonson_sample_py_script="${AUTOMATIZATION_PROJECT_PATH_WINDOWS_SYNTAX}\can_be_reused\old_tools\reduce_moonson_samples.py"
python_exe_='C:\Program Files\Python35\python.exe' 
current_app_output_folder_inside_the_phone="app_output_folder"
# Loading libraries
echo "--- Loading utils.sh library .... "
sleep 1
source ${AUTOMATIZATION_PROJECT_PATH}/utils.sh
echo "---  $TESTING_UTILS_SOURCING"

echo "--- Loading parsing_utils.sh library .... "
sleep 1
source ${AUTOMATIZATION_PROJECT_PATH}/parsing_utils.sh
echo "---  $TESTING_PARSING_UTILS_SOURCING"


freq_dict_of_little_socket_google_pixel=([0]="0" [1]="576000" [2]="1363200" [3]="1804800")
freq_dict_of_medium_socket_google_pixel=([0]="0" [1]="652800" [2]="1478400" [3]="2208000")
freq_dict_of_big_socket_google_pixel=([0]="0" [1]="806400" [2]="1766400" [3]="2400000")


function print_really_tested_configuration_with_good_frequency(){
    
    
    #0,1,2,4,0,2,  0,  0  -> [0,2,2,2,0,2,   0,   0]
    configuration_in_google_pixel_format_=$1
    last_frequency_level_on_little_socket_=$2

    # getting exact values of frequencies
    configuration_really_tested=()
    IFS=',' read -r -a configurations_array <<< "$configuration_in_google_pixel_format_"
    
    for  i in ${!configurations_array[@]};  
    do
        #echo "---++ Frequency level of core $i is  ${configurations_array[$i]}"
        if [ $i -lt 6 ]; then
            frequency_level=${configurations_array[$i]}
            if [ "$frequency_level" -ne "0" ]; then
                #echo "--- Last frequency level considered: $frequency_level, on core $i"
                configuration_really_tested+=($last_frequency_level_on_little_socket_)
            else 
                configuration_really_tested+=($frequency_level) # generic_format+=0
            fi 
         
            #echo "current configuration : $(echo_array ${generic_format[@]})"  # how to pass an array as parameter
        elif [ $i -eq 6 ]; then 
            frequency_level=${configurations_array[$i]}
            #echo " ---++ Adding this frequency $frequency_level to configuration "
            configuration_really_tested+=($frequency_level)
            
        elif [ $i -eq 7 ]; then 
            frequency_level=${configurations_array[$i]}
            #echo " ---++ Adding this frequency $frequency_level to configuration "
            configuration_really_tested+=($frequency_level)
          
        fi
    done
    #echo " ---++ processing finished:"; echo_array ${configuration_really_tested[@]}
    echo_csv_array ${configuration_really_tested[@]}
    #return $configuration_really_tested
}


function get_last_frequency_level_on_little_socket(){
    
    configuration_to_test_=$1
    last_frequency_level=0
    #echo "--- In function  get_last_frequency_level_on_little_socket: >${configuration_to_test_}<"
    IFS=',' read -r -a configurations_array <<< "$configuration_to_test_"
    for  i in ${!configurations_array[@]};  
    do
         if [ $i -lt 6 ]; then
            #echo "--- Frequency level of core $i is  ${configurations_array[$i]}"
            frequency_level=${configurations_array[$i]}
            if [ "$frequency_level" -ne "0" ]; then
                #echo "--- Last frequency level considered: $frequency_level, on core $i"
                last_frequency_level=$frequency_level
            fi
        fi  
    
    
    done
    return $last_frequency_level
}


function print_really_tested_configuration(){
    configuration=$1
    #echo "--- In function  print_really_tested_configuration: >${configuration}<"
    get_last_frequency_level_on_little_socket "${configuration}"
    last_frequency_level_on_little_socket=$?
    #echo "--- Last frequency level considered: $last_frequency_level_on_little_socket"

    #print_really_tested_configuration_with_good_frequency $configuration_in_google_pixel_format $last_frequency_level_on_little_socket
    really_tested_configuration=$(print_really_tested_configuration_with_good_frequency $configuration_in_google_pixel_format $last_frequency_level_on_little_socket)
    echo $really_tested_configuration
}

function print_really_tested_human_readable_configuration(){
    configuration=$1
    #echo "--1 Configuration at this time  $configuration"
    configuration_="${configuration:0:11}-${configuration:12:14}"
    #echo "--2 Configuration at this time  $configuration_"
    configuration=${configuration_:0:13}-${configuration_:14:15}
    #echo "--3 Configuration at this time  $configuration"
    echo $configuration | sed 's/,//g'
}

function generate_summary_file_with_experiment_really_realized(){
    #this file takes as input a file like this 
    old_summary_file_folder=$1
    output_folder=$2

    for summary_file in $old_summary_file_folder/*.csv; do
        echo "--- Processing file $summary_file in folder $old_summary_file_folder"
        summary_file_name="$(basename -- $summary_file)"
        new_summary_file=${output_folder}/${summary_file_name::-4}_with_configuration_really_tested.csv

        mv $new_summary_file ${PROJECT_TRASH_FOLDER}/${summary_file_name}_deleted__$(date +'%d%h%y_%H_%M_%S')
        touch $new_summary_file
        is_header=1
        while IFS=, read -r configurations generic_format exact_frequency_generic google_pixel_format exact_frequency_google_pixel energy avg_power total_workload energy_efficiency;  do
            if [ "$is_header" -ne "0" ]; then
                echo "--- Reading header $configurations and $exact_frequency_google_pixel"
                echo "--- Creating the file $new_summary_file" 
                echo "configurations,generic format,exact frequency,google pixel format,exact frequencies,phone energy,phone power,workload,energy by workload" > $new_summary_file
                is_header=0
            else 

                #generic_format exact_frequency_generic  exact_frequency_google_pixel
                google_pixel_format=$(echo $google_pixel_format |   tr -d '\r' )
                echo " -- Cleaning generic format of configuration >$google_pixel_format<"
                configuration_in_google_pixel_format=${google_pixel_format:1:-1} # removing first and last hooks
                configuration_in_google_pixel_format=$(echo "$configuration_in_google_pixel_format" | sed 's/ //g' | sed 's/-/,/g' ) # removing spaces and replacing dashes by commas
               
                echo "-- Getting the configuration relly tested from the $configuration_in_google_pixel_format"
                
               
                really_tested_google_pixel_format_=$(print_really_tested_configuration $configuration_in_google_pixel_format)
                echo " really tested google pixel format : >$really_tested_google_pixel_format_<"
                 

                really_tested_configuration_in_google_pixel_format=${really_tested_google_pixel_format_:1:-1} # removing first and last hooks
                really_tested_configuration_in_google_pixel_format=$(echo "$really_tested_configuration_in_google_pixel_format" | sed 's/ //g' | sed 's/-/,/g' ) # removing spaces and replacing dashes by commas
           
              
                echo " -- Getting generic format of configuration $really_tested_configuration_in_google_pixel_format"
                really_tested_generic_format=$(print_generic_format_from_configuration $really_tested_configuration_in_google_pixel_format)
                echo " ----- Generic format: $really_tested_generic_format"
                 
                really_tested_configuration_in_generic_format=${really_tested_generic_format:1:-1} # removing first and last hooks
                really_tested_configuration_in_generic_format=$(echo "$really_tested_configuration_in_generic_format" | sed 's/ //g' | sed 's/-/,/g' )
                #echo " -- Getting generic format with exact frequencies of configuration $configuration_in_generic_format"
                really_tested_exact_frequency_generic=$(print_generic_format_with_exact_frequencies_values $really_tested_configuration_in_generic_format)
                echo " -- Generic format with exact frequencies:  $really_tested_exact_frequency_generic"


                echo " -- Getting exact frequencies of configuration $really_tested_configuration_in_google_pixel_format"
                really_tested_exact_frequency_google_pixel=$(echo_configuration_with_exact_value_of_frequencies $really_tested_configuration_in_google_pixel_format)
                echo " -- Exact frequencies: $really_tested_exact_frequency_google_pixel"

                echo " -- Getting human readable format of configuration $really_tested_configuration_in_google_pixel_format"
                really_tested_configurations=$(print_really_tested_human_readable_configuration $really_tested_configuration_in_google_pixel_format)
                echo " -- Human readable format $really_tested_configurations"
                print_really_tested_human_readable_configuration $really_tested_configuration_in_google_pixel_format
 echo "configurations,generic format,exact frequency,google pixel format,exact frequencies,phone energy,phone power,workload,energy by workload"
    


                echo "$really_tested_configurations,$really_tested_generic_format,$really_tested_exact_frequency_generic,\
$really_tested_google_pixel_format_,$really_tested_exact_frequency_google_pixel,\
$energy,$avg_power,$total_workload,$energy_efficiency" >> $new_summary_file
:<<'END_COMMENT'
                echo "$configurations,$generic_format,$exact_frequency_generic,$google_pixel_format, $exact_frequency_google_pixel, \
$energy,  $avg_power, $total_workload, $energy_efficiency, $really_tested_configurations, \
$really_tested_generic_format,$really_tested_exact_frequency_generic, \
$really_tested_google_pixel_format_, $really_tested_exact_frequency_google_pixel ">> $new_summary_file

END_COMMENT
            
            fi
        
        done < $summary_file 
        
    done 
}

old_summary_file_folder=$"${AUTOMATIZATION_PROJECT_PATH}/old_summary_files_only"
output_folder="${AUTOMATIZATION_PROJECT_PATH}/summary_files_only"
generate_summary_file_with_experiment_really_realized $old_summary_file_folder $output_folder
    #this file takes as input a file like this 
