#!/usr/bin/bash



# This tool takes as input a folder and for each subfolder that contains a summary file
# it correct the error related to bad computation of generic format of configurations
# it also add tow columns for starting cc_info and ending cc_info in each summary file

PROJECT_PATH="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization"
SCRIPT_PATH="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/old_tools"
echo "--- Walking through directory $SUMMARY_FOLDER"

AUTOMATIZATION_PROJECT_PATH="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization"
PROJECT_TRASH_FOLDER="${AUTOMATIZATION_PROJECT_PATH}/can_be_reused/old_tools/trash"

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





function produce_correct_summary_file(){
    #this file takes as input a file like this 
    old_summary_file=$1
    PROJECT_TRASH_FOLDER_=$2
    tmp_summary_file_=${old_summary_file::-4}__tmp.csv 
    PHONE_NAME_="google_pixel_4a_5g"
    phone_format_header_in_file="google pixel format"

    touch $tmp_summary_file_
    is_header=1
    while IFS=, read -r configurations generic_format_ exact_frequency phone_format exact_frequencies phone_energy \
                    phone_power workload energy_by_workload ; do
        if [ "$is_header" -ne "0" ]; then
            echo "--- Reading header $configurations and $exact_frequency_google_pixel"
            echo "--- Creating the file $tmp_summary_file_" 
            echo "configurations,generic format,exact frequency,${phone_format_header_in_file},exact frequencies,phone energy,\
                    phone power,workload,energy by workload,starting cc_info,ending cc_info" >  $tmp_summary_file_            
            is_header=0
        else 
            #generic_format exact_frequency_generic  exact_frequency_google_pixel
            phone_format=$(echo $phone_format |   tr -d '\r' )
            echo " -- Cleaning phone format of configuration >$phone_format<"
            configuration_in_phone_format=${phone_format:1:-1} # removing first and last hooks
            configuration_in_phone_format=$(echo "$configuration_in_phone_format" | sed 's/ //g' | sed 's/-/,/g' ) # removing spaces and replacing dashes by commas
            #echo " -- Getting generic format of configuration $configuration_in_phone_format"
            generic_format=$(print_generic_format_from_configuration $configuration_in_phone_format $PHONE_NAME_)
            echo " ----- Generic format: $generic_format"
            
            configuration_in_generic_format=${generic_format:1:-1} # removing first and last hooks
            configuration_in_generic_format=$(echo "$configuration_in_generic_format" | sed 's/ //g' | sed 's/-/,/g' )
            #echo " -- Getting generic format with exact frequencies of configuration $configuration_in_generic_format"
            exact_frequency_generic=$(print_generic_format_with_exact_frequencies_values $configuration_in_generic_format $PHONE_NAME_)
            echo " -- Generic format with exact frequencies:  $exact_frequency_generic"

            #echo " -- Getting exact frequencies of configuration $configuration_in_phone_format"
            exact_frequency_phone=$(echo_configuration_with_exact_value_of_frequencies $configuration_in_phone_format  $PHONE_NAME_)
            #exact_frequency_phone=$(echo "$exact_frequency_phone" | sed 's/,/- /g')
            #exact_frequency_phone="[$exact_frequency_phone]"
            echo " -- Exact frequencies: $exact_frequency_phone"
            starting_cc_info=0
            ending_cc_info=0
            energy_by_workload=$(echo $energy_by_workload | sed 's/\r$//' | sed 's/\n//g'  )
            echo "$configurations,$generic_format,$exact_frequency_generic,$phone_format,$exact_frequency_phone,\
            ${phone_energy},$phone_power,$workload,$energy_by_workload,$starting_cc_info,$ending_cc_info" >>  $tmp_summary_file_


        fi
    done < $old_summary_file

    mv $old_summary_file ${PROJECT_TRASH_FOLDER_}/summary_file_deleted_on_$(date +'%d%h%y_%H_%M_%S')
    mv $tmp_summary_file_ $old_summary_file

}


function correct_results_folder(){
    many_result_folders=$1


    for current_result_directory in  ${many_result_folders}/*/ ; do
        echo "--- Processing configutation directory $current_result_directory"
        for current_file in ${current_result_directory::-1}/* ; do
            zero_if_summary=$(echo $current_file | grep -q summary ; echo $?)
            if [ "$zero_if_summary" -eq "0" ]; then
                echo "--- Processing summary file $current_file"
                produce_correct_summary_file  ${current_file} "${PROJECT_TRASH_FOLDER}" 
            fi
        done

    done
}

result_folder="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/GOOGLE_PIXEL_RESULTS"
correct_results_folder $result_folder