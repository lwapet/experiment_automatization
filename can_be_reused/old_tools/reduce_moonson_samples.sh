#!/usr/bin/bash



# this script takes as input a result folder coming from automatisation 
# it first function reduce de number of moonson sample in the file configuration_tested/configuration_mesurement.csv
# If the input folder containts summaries in mWs, it recomputes de powermeter summary file and replace the experiment summary. 
# the second function reduce_samples_datas_in_first_experiments realizes it. 

AUTOMATIZATION_PROJECT_PATH="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization"
PROJECT_TRASH_FOLDER="${AUTOMATIZATION_PROJECT_PATH}/can_be_reused/old_tools/trash"
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



function reduce_many_samples_folders(){
    experiment_output_folder_=$1


    for current_configuration_directory in  $experiment_output_folder_/*/ ; do
        echo "--- Processing configutation directory $current_configuration_directory"
        mesurement_file=${current_configuration_directory}configuration_mesurement.csv
        new_mesurement_file=${mesurement_file::-4}__reduced.csv  ######################################
        echo "--- 0 - Mesurement file $mesurement_file"
#PROJECT_PATH="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization"
#PROJECT_PATH_WINDOWS_SYNTAX="C:\Users\lavoi\opportunist_task_on_android\scripts_valuable_files\experiment_automatization"
        touch $new_mesurement_file
        #echo "No" > $new_mesurement_file
        mesurement_file_to_move=$mesurement_file
        mesurement_file=$(echo $mesurement_file | sed 's/\//\\/g')  #$(echo $mesurement_file | sed "s///\\/")
        echo "--- 1 - Mesurement file $mesurement_file"
        mesurement_file=$(echo $mesurement_file | sed 's/\\mnt\\c/C:/g')
        echo "--- 2 - Mesurement file $mesurement_file"
        new_mesurement_file=$(echo $new_mesurement_file | sed 's/\//\\/g')
        new_mesurement_file=$(echo $new_mesurement_file | sed 's/\\mnt\\c/C:/g')

        echo "--- 0 - python_exe_ $python_exe_"
        python_exe_=$(echo $python_exe_ | sed 's/\//\/\//g' )
        echo "--- 1 - python_exe_ $python_exe_"

        echo "--- 0 reduce_moonson_sample_py_script $reduce_moonson_sample_py_script"
        reduce_moonson_sample_py_script=$(echo $reduce_moonson_sample_py_script | sed 's/\//\/\//g' )
        echo " --- 1 reduce_moonson_sample_py_script $reduce_moonson_sample_py_script"
        
        #cmd.exe /c  "${python_exe_}"  ${monson_power_meter_script_}  1 $monsonn_output_voltage_ $calibration_duration_ $csv_output_file_  
        echo "command :  cmd.exe /c  "${python_exe_}"  "${reduce_moonson_sample_py_script}"  1 $mesurement_file $new_mesurement_file  "
        #/mnt/c/Windows/SysWOW64/cmd.exe /c dir "${new_mesurement_file}"
        /mnt/c/Windows/SysWOW64/cmd.exe /c  "${python_exe_}"  "${reduce_moonson_sample_py_script}"  1 $mesurement_file "$new_mesurement_file"
        echo "--- Romoving the havy measurement file"
        mv $mesurement_file_to_move $PROJECT_TRASH_FOLDER
        sleep 2
        ls $mesurement_file_to_move
        sleep 2
    done
}


# It could be good to used this function before reducing the data with the first one
# So use it in the original mesurement file. 
function recompute_powermeter_summary_from_mWs_to_mAh(){
    #  recompute powermeter summary file
   

        mesurement_file=$1 
        number_of_samples_per_second_=$2 


        mesurement_file=$(echo $mesurement_file | sed 's/\//\\/g')  #$(echo $mesurement_file | sed "s///\\/")
        #echo "--- 1 - Mesurement file $mesurement_file"
        mesurement_file=$(echo $mesurement_file | sed 's/\\mnt\\c/C:/g')
        #echo "--- 2 - Mesurement file $mesurement_file"
      


        #echo "--- Recomputing powermeter summary from $mesurement_file, having $number_of_samples_per_second_ per seconds the result are simply echoed.  (to delete this line)"
        #echo "--- Command :  cmd.exe /c  "${python_exe_}"  "${reduce_moonson_sample_py_script}"  2 $mesurement_file $number_of_sample_per_second_ "
        #cmd.exe /c  "${python_exe_}"  "${reduce_moonson_sample_py_script}"  2 $mesurement_file "$number_of_samples_per_second_"
        result=$(cmd.exe /c  "${python_exe_}"  "${reduce_moonson_sample_py_script}"  2 $mesurement_file "$number_of_samples_per_second_")
        echo  "$result"

}

function parse_and_collect_configuration_results(){
    global_experiment_output_folder_path__=$1
    configuration_to_test__=$2
    current_configuration_user_friendly__=$3
    correct_powermeter_summary_file_name__=$4
    correct_raw_result_file_name__=$5

    tmp_experiment_folder_name=$(ls $global_experiment_output_folder_path__ | grep $current_configuration_user_friendly__ )
    tmp_experiment_folder_path=$global_experiment_output_folder_path__/$tmp_experiment_folder_name

    raw_result_file=${global_experiment_output_folder_path__}/${correct_raw_result_file_name__}
    tmp_powermeter_summary_output_file="${tmp_experiment_folder_path}/$correct_powermeter_summary_file_name__"

    echo "--- Parsing result from  $tmp_experiment_folder_path to $raw_result_file"
    touch $raw_result_file  # creating result file if it is not the case. 
    
    echo "--- Getting exact configuration with frequency"
    configuration_with_exact_value_of_frequencies=$(echo_configuration_with_exact_value_of_frequencies ${configuration_to_test__}) 
    echo "--- Configuration with frequencies = $configuration_with_exact_value_of_frequencies"
    
    echo "--- Getting the powermeter summary"
    powermeter_summary=$(read_all_file_line_by_line "$tmp_powermeter_summary_output_file")
    echo -e "--- Powermeter summary: \n$powermeter_summary"
    
    echo "--- Getting the total energy consumed"
    energy=$(echo -e $powermeter_summary | grep "Consumed Energy (mAh)" | cut -d ':' -f 2 | sed 's/ //g')
    echo "--- Energy consumed = $energy"

    echo "--- Getting the average power"
    avg_power=$(echo -e $powermeter_summary | grep "Avg power (mW)" | cut -d ':' -f 2 | sed 's/ //g')
    echo "--- Avg Power = $avg_power"

    
    echo "--- Printing the total threads summary command : print_total_workload "${tmp_experiment_folder_path}" "${current_app_output_folder_inside_the_phone}" "${configuration_to_test__}" "${PROJECT_TRASH_FOLDER}"" 
    threads_results_string=$(print_thread_summary "${tmp_experiment_folder_path}" "${current_app_output_folder_inside_the_phone}" "${configuration_to_test__}" "${PROJECT_TRASH_FOLDER}")
    echo -e "--- Thread results \n$threads_results_string" 

    echo "--- Counting the total workload command : print_total_workload "${tmp_experiment_folder_path}" "${current_app_output_folder_inside_the_phone}" "${configuration_to_test__}" "${PROJECT_TRASH_FOLDER}" "
    total_workload=$(print_total_workload "${tmp_experiment_folder_path}" "${current_app_output_folder_inside_the_phone}" "${configuration_to_test__}" "${PROJECT_TRASH_FOLDER}")
    echo "--- Total workload : $total_workload"

    echo "--- Getting energy efficiency"
    if [ $total_workload -eq "0" ]; then
        echo "--- The workload is null so we give the arbitrary value 12275 to the energy efficiency "; sleep 3
        energy_efficiency=12275  # arbitrary value borrowed from previous experiments
    else
        energy_efficiency=$(awk -v var1="$energy" -v var2="$total_workload" 'BEGIN {print var1/var2}')  
    fi
    
    echo "--- Energy efficiency: $energy_efficiency"

    echo -e  "--- Building what we will add to the total result file command \n------\n (build_configuration_raw_result "${current_configuration_user_friendly__}" "${configuration_to_test__}" \
                    "${configuration_with_exact_value_of_frequencies}" \
                "${powermeter_summary}" "${threads_results_string}" "${energy}" \
                "${total_workload}" "${energy_efficiency}"  \n------\n"
    final_result_as_string="$(build_configuration_raw_result "${current_configuration_user_friendly__}" "${configuration_to_test__}" \
                    "${configuration_with_exact_value_of_frequencies}" \
                "${powermeter_summary}" "${threads_results_string}" "${energy}" \
                "${total_workload}" "${energy_efficiency}")"
    echo -e "--- Final result to print to File \n "${final_result_as_string}" "  # NOTE : USE "" around the string variable to correctly print starts

    echo "--- Writing to the total result file $raw_result_file"
    echo -e "${final_result_as_string}" >> $raw_result_file   # NOTE : USE "" around the string variable to correctly print starts


    
    echo "--- Writing a temporary file for the main script with format energy_power_workload_energyByWorkload"
    echo -e "Consumed Energy (mAh): ${energy} \nAvg power (mW): ${avg_power} \nTotal Workload: ${total_workload} \nEnergy Efficiency: ${energy_efficiency}" > ${tmp_experiment_folder_path}/energy_power_workload_energyByWorkload
}
      

function recompute_raw_result_and_total_summary_for_second_experiments(){
   

    global_experiment_folder_path_=$1
    old_global_summary_file_name_=$2
    correct_global_summary_file_name_=$3

    configuration_mesurement_file_name_to_consider=$4 #configuration_mesurement.csv
    number_of_samples_per_second=$5

    correct_powermeter_summary_file_name_=$6 #correct_powermeter_summary.txt
    correct_raw_result_file_name_=$7
    

    old_global_summary_file=${global_experiment_folder_path_}/${old_global_summary_file_name_}
    correct_global_summary_file=${global_experiment_folder_path_}/${correct_global_summary_file_name_}
    number_of_samples_per_mi_second=$((number_of_sample_per_second / 2))
    echo "--- In function recompute_raw_result_and_total_summary_for_second_experiments"
    echo "--- Reading summary file $old_global_summary_file"
    
    is_header=1
    while IFS=, read  -r configurations generic_format exact_frequency_generic google_pixel_format exact_frequency_google_pixel energy avg_power total_workload energy_efficiency; do
        if [ "$is_header" -ne "0" ]; then
            echo "--- Reading header $configurations and $exact_frequency_google_pixel" # we don't consider the header
            is_header=0
            echo "--- creating the result file, adding the header to the file"
            #echo "configurations,generic format,exact frequency,google pixel format,exact frequencies,phone energy,phone power,workload,energy by workload" > ${correct_global_summary_file} 
            echo "$configurations,$generic_format,$exact_frequency_generic,$google_pixel_format,$exact_frequency_google_pixel,$energy,$avg_power,$total_workload,$energy_efficiency" >  ${correct_global_summary_file} 
        else 

    

            configuration_to_test=${google_pixel_format:1:-1} # removing first and last hooks
            configuration_to_test=$(echo "$configuration_to_test" | sed 's/ //g' | sed 's/-/,/g' ) # removing spaces and replacing dashes by commas
            current_configuration_user_friendly=$configurations
            
            tmp_experiment_folder_name=$(ls $global_experiment_folder_path_ | grep $current_configuration_user_friendly )
            tmp_experiment_folder_path=${global_experiment_folder_path_}/$tmp_experiment_folder_name                

            mesurement_file=$tmp_experiment_folder_path/$configuration_mesurement_file_name_to_consider 
            echo -e "--- Parsing the, old summary file, results we consider are in in  $mesurement_file,\n--- Number of samples per second: $number_of_samples_per_second"
            ############# first step: modifying the raw result file. 
            
            correct_powermeter_summary_file=$tmp_experiment_folder_path/${correct_powermeter_summary_file_name_}
            #recompute_powermeter_summary_from_mWs_to_mAh "$mesurement_file" $number_of_samples_per_second
            powermeter_summary=$(recompute_powermeter_summary_from_mWs_to_mAh "$mesurement_file" $number_of_samples_per_second)
            echo -e "--- Powermeter summary :  \n ${powermeter_summary}"
         
            echo "---  Writing the result in the  file : $correct_powermeter_summary_file"

            echo -e "$powermeter_summary" > $correct_powermeter_summary_file
            
          
             
       
            


            ############ Second step: computing raw result and summary csv line


            echo "--- Recomputing the raw result of configuration $current_configuration_user_friendly"
            echo "--- Command  parse_and_collect_configuration_results ${global_experiment_folder_path_} ${configuration_to_test} ${current_configuration_user_friendly} \
                                    ${correct_powermeter_summary_file_name_} $correct_raw_result_file_name_"

            parse_and_collect_configuration_results ${global_experiment_folder_path_} ${configuration_to_test} ${current_configuration_user_friendly} \
                                    ${correct_powermeter_summary_file_name_} $correct_raw_result_file_name_
                                           
    
            sleep 2
            

            echo "--- Obtaining experiment summary result to add to result folder"
            experiment_results=$(read_all_file_line_by_line "${tmp_experiment_folder_path}/energy_power_workload_energyByWorkload")
            echo "--- From file $experiment_results"

            energy_=$(echo -e  $experiment_results   | grep "Consumed Energy" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
            echo "--- Experiment result, Energy consumed = $energy_"
            avg_power_=$(echo -e $experiment_results | grep "Avg power" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
            echo "--- Experiment result, Avg Power = $avg_power_"
            total_workload_=$(echo -e $experiment_results | grep "Total Workload" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
            echo "--- Experiment result, Total Workload = $total_workload_"
            energy_efficiency_=$(echo -e $experiment_results | grep "Energy Efficiency" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
            echo "--- Experiment result, Energy Efficiency = $energy_efficiency_"
            echo "--- Adding result to summary file" 
            exact_frequency_google_pixel=$(echo $exact_frequency_google_pixel |   tr -d '\r' )
        
          
            
            echo "--- The file $correct_global_summary_file exists we just appending the result to the file"
            echo "$configurations,$generic_format,$exact_frequency_generic,$google_pixel_format,$exact_frequency_google_pixel,$energy_,$avg_power_,$total_workload_,$energy_efficiency_" >> ${correct_global_summary_file}
        
            echo "--- Experiments performed on configuration $configurations"
        

        fi

    done < $old_global_summary_file
}



## to test on second experiments (energy in mAh, when all samples datas are present) experiments (with an exemple of folder)
#experiment_output_folder="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/old_tools/output_folder_to_test_monsoon_sampling_reduction"
#experiment_output_folder="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/SECOND_RESUTLS"
#reduce_many_samples_folders_in_second_experiments $experiment_output_folder


global_experiment_folder_path_="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/old_tools/FIRST_RESULTS_Energy_in_mWs_with_correct_summary"
#global_experiment_folder_path_="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/FIRST_RESULTS"
## to test on second experiment (energy in mWs)
#echo "--- Calling function recompute_raw_result_and_total_summary_for_second_experiments"
#recompute_raw_result_and_total_summary_for_second_experiments  ${global_experiment_folder_path_} \
#    "summary.csv" "correct_summary_file.csv"  \
#    configuration_mesurement.csv 5000 \
#    "correct_powermeter_summary.txt" "correct_raw_result_file.txt" 


#experiment_output_folder="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/old_tools/FIRST_RESULTS_Energy_correct_summary_and_reduced"
#reduce_many_samples_folders $experiment_output_folder

experiment_output_folder="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/old_tools/SECOND_RESULTS_Reduced"
reduce_many_samples_folders $experiment_output_folder