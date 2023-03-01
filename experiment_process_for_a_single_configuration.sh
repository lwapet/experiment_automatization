#!/usr/bin/bash
# scritp to run experiments automatically
## NOTE : This code version is for google pixel 4a 5g
## This function uses global variable defined in the main script
## This function should locally produce a file named energy_power_workload_energyByWorkload referring to the second part headers of the summary result file. 
## The input to complete for the line are     phone energy,phone power,workload,energy by workload
function perform_experiment_for_one_configuration(){
    configuration_to_test__=$1
    current_configuration_user_friendly__=$2
    PHONE_NAME_=$3
    

    # Used during development phase to avoid wasting time by redoing all the experiment flow
    previous_experiment_folder_to_delete=$PROJECT_TRASH_FOLDER/${tmp_experiment_folder_name}__deleted__on__$(date +'%d%h%y_%H_%M_%S')
    if [ "$CLEAN_TMP_FOLDER" -ne "0" ]; then
        echo "--- Cleaning the tmp expermiment folder : $tmp_experiment_folder_path"
        mv $tmp_experiment_folder_path $previous_experiment_folder_to_delete
        mkdir $tmp_experiment_folder_path
    fi


    #####  CALIBRATION PHASE
    

    if [ "$VERIFY_BATTERY_LEVEL" -ne "0" ]; then
        ## Second step : verifying the battery level
        echo "--- Second step  : verifying the battery level"
        verify_battery_level "${adb}" $experiment_battery_level "$drainer_app_package_name" \
        "$drainer_app_main_activity" "$DRAINER_APK_PATH__WINDOWS_SYNTAX" "$level_for_reducing_charging" \
        charge_limit_file_dict "${ANDROID_SWT}" "${monkeyrunner_bat}" "$monkey_runner_script" "${charge_stop_level_file}" $PHONE_NAME
    fi 

    if [ "$CALIBRATE_POHNE_CORE_FREQUENCY" -ne "0" ]; then
        ## Third step calibrating phone core frequency
        ## Note that we are limited because we can only set frequency of the hole socket
        ## So this code will considere the frequency level of the last core where the frequency level is not null 
        echo "--- Third step calibrating phone core frequency"
        reset_cpu_configuration "${adb}" "$phone_system_cpu_folder" $PHONE_NAME
        set_core_frequency "${adb}"  $configuration_to_test__ "$phone_system_cpu_folder"  $PHONE_NAME
        #reset_cpu_configuration "${adb}" "$phone_system_cpu_folder"
    fi 


    if [ "$CALIBRATE_MONSOON_POWER_METER" -ne "0" ]; then
        # Fourth step : monsoone powerweter calibration
        calibrate_monsoon_power_meter  "${python_exe}" "${monson_power_meter_script}" \
        "${monsonn_output_voltage}" $calibration_duration "${tmp_csv_output_file}"
    fi

    ##### EXPERIMENT PHASE
    if [ "$START_BENCHMARKING_APP_AND_PIN_THREADS" -ne "0" ]; then
        # Starting the banchmarkin app
        echo "--- starting the benchmarking app "
        start_benchmarking_app  "${adb}" "${sdcard_path_in_phone}" "${experiment_folder_name_inside_the_phone}" \
                        "${current_configuration_file_name_inside_the_phone}" "${configuration_to_test__}" \
                        "${current_app_output_folder_inside_the_phone}" "${experiment_app_package_name}" \
                            "${EXPERIMENT_APK_PATH__WINDOWS_SYNTAX}" "${experiment_app_main_activity}" \
                        "$experiment_duration" "${current_experiment_duration_file_name_inside_the_phone}"

        echo "---- waiting for benchmarking app thread to be pinned and to be ready"
        wait_for_app_threads_to_be_in_experiment_phase "${adb}" "${configuration_to_test__}" "${sdcard_path_in_phone}" \
                        "${experiment_folder_name_inside_the_phone}" "${current_app_output_folder_inside_the_phone}" \
                        "${cc_info_file_path_inside_the_phone}" "${tmp_experiment_folder_path}"

        
    fi


    if [ "$PERFORMS_POWERMETER_SAMPLING" -ne "0" ]; then
        echo " --- Starting power meter sampling for about $experiment_duration seconds "  
        start_powermeter_sampling "${python_exe}" "${monson_power_meter_script}"  "${monsonn_output_voltage}" \
                    "$experiment_duration" "${tmp_csv_output_file}" "$tmp_powermeter_summary_output_file_windows_syntax"
    fi


    if [ "$WAIT_FOR_THREADS_AND_COLLECT_RESULTS" -ne "0" ]; then
        echo " --- experiment folder path  $tmp_experiment_folder_path"
        wait_for_app_threads_to_be_ended_collect_results "${adb}" $configuration_to_test__   "${sdcard_path_in_phone}" \
        "${experiment_folder_name_inside_the_phone}" "${current_app_output_folder_inside_the_phone}" "${tmp_experiment_folder_path}" \
        "${tmp_experiment_folder_path_windows_syntax}" "${cc_info_file_path_inside_the_phone}"
    fi




    # Result parsing phase. Note this step reuse functions from util.sh and parsing_utils.sh
    if [ "$PARSE_AND_COLLECT_CURRENT_CONFIGURATION_RESULT" -ne "0" ]; then
        
        echo "--- Parsing result from  $tmp_experiment_folder_path to $raw_result_file"
        touch $raw_result_file  # creating result file if it is not the case. 
        
        echo "--- Getting exact configuration with frequency"
        configuration_with_exact_value_of_frequencies=$(echo_configuration_with_exact_value_of_frequencies ${configuration_to_test__} $PHONE_NAME) 
        echo "--- Configuration with frequencies = $configuration_with_exact_value_of_frequencies"
        
        echo "--- Getting the powermeter summary"
        powermeter_summary=$(read_all_file_line_by_line "$tmp_powermeter_summary_output_file")
        echo -e "--- Powermeter summary: \n$powermeter_summary"
        
       
    
        echo "--- Getting the total energy consumed of the google pixel"
        energy=$(echo -e $powermeter_summary | grep "Consumed Energy (mAh)" | cut -d ':' -f 2 | sed 's/ //g')
        #energy=$(print_total_energy "${powermeter_summary}" "${PHONE_NAME_}" "${tmp_experiment_folder_path}" \
        #       "${current_app_output_folder_inside_the_phone_}" "${configuration_to_test_}" "${project_trash_folder_}")
                  
        echo "--- Energy consumed = $energy"

        
        starting_cc_info=$(print_cc_info  "${tmp_experiment_folder_path}" "starting")       
        echo "--- Starting cc_info = $starting_cc_info"

        ending_cc_info=$(print_cc_info  "${tmp_experiment_folder_path}" "ending")       
        echo "--- Ending cc_info = $ending_cc_info"

        echo "--- Getting the average power"
        avg_power=$(echo -e $powermeter_summary | grep "Avg power (mW)" | cut -d ':' -f 2 | sed 's/ //g')
        echo "--- Avg Power = $avg_power"

        

        echo "--- Printing the total threads summary" 
        threads_results_string=$(print_thread_summary "${tmp_experiment_folder_path}" "${current_app_output_folder_inside_the_phone}" "${configuration_to_test__}" "${PROJECT_TRASH_FOLDER}")
        echo -e "--- Thread results \n$threads_results_string" 

        echo "--- Counting the total workload command : print_total_workload "${tmp_experiment_folder_path}" "${current_app_output_folder_inside_the_phone}" "${configuration_to_test__}" "${PROJECT_TRASH_FOLDER}" "
        total_workload=$(print_total_workload "${tmp_experiment_folder_path}" "${current_app_output_folder_inside_the_phone}" "${configuration_to_test__}" "${PROJECT_TRASH_FOLDER}")
        echo "--- Total workload : $total_workload"

 

        echo "--- Getting energy efficiency"
        if [ $total_workload -eq "0" ]; then
            echo "--- The workload is null so we give the arbitrary value 12275 to the energy efficiency "; sleep 3
            energy_efficiency=12  # arbitrary value borrowed from previous experiments
        else
            energy_efficiency=$(awk -v var1="$energy" -v var2="$total_workload" 'BEGIN {print var1/var2}')  
        fi
       
        echo "--- Energy efficiency: $energy_efficiency"

        echo -e  "--- Building what we will add to the total result file command \n------\n (build_configuration_raw_result "${current_configuration_user_friendly__}" "${configuration_to_test__}" \
                        "${configuration_with_exact_value_of_frequencies}" \
                    "${powermeter_summary}" "${threads_results_string}" "${energy}" \
                    "${total_workload}" "${energy_efficiency}"  $starting_cc_info $ending_cc_info \n------\n"
        final_result_as_string="$(build_configuration_raw_result "${current_configuration_user_friendly__}" "${configuration_to_test__}" \
                        "${configuration_with_exact_value_of_frequencies}" \
                    "${powermeter_summary}" "${threads_results_string}" "${energy}" \
                    "${total_workload}" "${energy_efficiency}"  "$starting_cc_info" "$ending_cc_info")"
        echo -e "--- Final result to print to File \n "${final_result_as_string}" "  # NOTE : USE "" around the string variable to correctly print starts

        echo "--- Writing to the total result file"
        echo -e "${final_result_as_string}" >> $raw_result_file   # NOTE : USE "" around the string variable to correctly print starts

        echo "--- Removing previous tested configuration tmp_output folder"
        rm -rfv $previous_experiment_folder_to_delete
        echo "--- Moving the current experiment tmp_folder to the output result folder"
        cp -rf "${tmp_experiment_folder_path}" ${experiment_output_folder}/${current_configuration_user_friendly__}__experiment_folder__$(date +'%d%h%y_%H_%M_%S') 
        #cp -rf "${tmp_experiment_folder_path}" ${PROJECT_TRASH_FOLDER}/${current_configuration_user_friendly__}__experiment_folder__$(date +'%d%h%y_%H_%M_%S') 
        
        echo "writing a temporary file for the main script with format energy_power_workload_energyByWorkload_ccInfo"
        echo -e "Consumed Energy (mAh): ${energy} \nAvg power (mW): ${avg_power} \nTotal Workload: ${total_workload} \nEnergy Efficiency: ${energy_efficiency}\
                    \nStarting cc_info: ${starting_cc_info}   \nEnding cc_info: ${ending_cc_info}" > ${tmp_experiment_folder_path}/energy_power_workload_energyByWorkload_ccInfo
    fi

}

TESTING_SINGLE_EXPERIMENT_PROCESS_SOURCING="--- experiment_process_for_a_single_configuration.sh correctly loaded. "


:<<'END_COMMENT'

END_COMMENT