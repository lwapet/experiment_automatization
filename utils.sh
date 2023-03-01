#!/usr/bin/bash


function get_battery_level(){
    echo "--- Getting current battery level, adb command path: $1 "
    
    adb_=$1

    current_battery_level_=$("${adb_}" shell "dumpsys battery" </dev/null  | grep level  | cut -d ':' -f 2 | sed 's/ //g')

    current_battery_level_=$(echo $current_battery_level_ | tr -d '\r') # To remove the DOS carriage return (^M). 
    echo "--- Current battery level : ${current_battery_level_} "

    return $current_battery_level_

}

function verify_battery_level(){
    adb_=$1
    experiment_battery_level_=$2
    drainer_app_package_name_=$3
    drainer_app_main_activity_=$4
    DRAINER_APK_PATH__WINDOWS_SYNTAX_=$5
    level_for_reducing_charging_=$6
    local -n charge_limit_file_dict_=$7
    ANDROID_SWT_=$8
    monkeyrunner_bat_=$9
    monkey_runner_script_=${10}
    charge_stop_level_file_=${11}
    PHONE_NAME_=${12}

    

    echo "--- Verifying the battery level"
    get_battery_level "${adb_}"
    current_battery_level=$?
    # current_battery_level=$("${adb_}" shell "dumpsys battery" </dev/null  | grep level  | cut -d ':' -f 2 | sed 's/ //g')
    # current_battery_level=$(echo $current_battery_level | tr -d '\r') # To remove the DOS carriage return (^M). 
    # echo "current battery level : ${current_battery_level} "
    
    if [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
        echo "--- Forcing the experiment battery level to be 100 "
        experiment_battery_level_=100
    fi

    if [ "$current_battery_level" -eq "$experiment_battery_level_" ]; then
        echo "Current battery level: OKAY"
    elif [  "$current_battery_level" -gt "$experiment_battery_level_" ]; then
        echo "Current battery is high, so we need to drain battery"

        echo "----- Uninstalling drainer app"
        "$adb_" uninstall $drainer_app_package_name_  </dev/null
        echo "----- Installing drainer app"
        "$adb_" install "$DRAINER_APK_PATH__WINDOWS_SYNTAX_" </dev/null
        
        echo "------ Giving rights to drainer app"


        "$adb_" shell pm grant $drainer_app_package_name_  android.permission.DUMP   </dev/null
        "$adb_" shell pm grant $drainer_app_package_name_ android.permission.PACKAGE_USAGE_STATS  </dev/null
        "$adb_" shell pm grant $drainer_app_package_name_ android.permission.WRITE_EXTERNAL_STORAGE     </dev/null

        echo "----- Starting drainer app"
        "$adb_" shell  "sleep 1  
            am start -n $drainer_app_package_name_/$drainer_app_main_activity_"  </dev/null
        
        sleep 1
        APP_PID=$("$adb_" shell "ps -A | grep $drainer_app_package_name_" </dev/null | awk '{ print $2 }')
        APP_PID=$(echo $APP_PID | tr -d '\r') # To remove the DOS carriage return (^M). 

        echo "--- Limiting power supply to battery "
        if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
            echo "--- Command "$adb_" shell \"echo 0 > ${charge_limit_file_dict_[$PHONE_NAME_]}\" </dev/null"
            "$adb_" shell "echo ${level_for_reducing_charging_} > ${charge_limit_file_dict_[$PHONE_NAME_]}" </dev/null
        elif [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
            echo "--- For the samsung the experiment  battery level is 100 by default "
            #echo "command : "$adb_" shell \"su -c \'echo 0 > ${charge_limit_file_dict_[$PHONE_NAME_]}\'\" </dev/null "
            #"$adb_" shell "su -c 'echo 0 > ${charge_limit_file_dict_[$PHONE_NAME_]}'" </dev/null
        fi


        echo "--- Drainer app started with PID =  $APP_PID " 
        cmd.exe /V /C "set ANDROID_SWT_="${ANDROID_SWT_}"&& "${monkeyrunner_bat_}" ${monkey_runner_script_}  1 ${drainer_app_package_name_} ${drainer_app_main_activity_}"

        get_battery_level "${adb_}"
        current_battery_level=$?

        while [ "$current_battery_level" -gt "$experiment_battery_level_" ]; do
            echo -e "--- The current battery level : ${current_battery_level}, greater than the experiment one :  $experiment_battery_level_ \n--- Waiting 60 second..."
            sleep 60
            get_battery_level "${adb_}"
            current_battery_level=$?
        done



        echo "--- Restoring power supply to battery "
        
        if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
            "$adb_" shell "echo -1 > ${charge_limit_file_dict_[${PHONE_NAME_}]}" </dev/null
        elif [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
            echo "--- For the samsung the experiment battery level is 100 by default "
            #"$adb_" shell "su -c 'echo 1 > ${charge_limit_file_dict_[${PHONE_NAME_}]}'" </dev/null
        fi


        sleep 10 # to drain again some amount of energy to do exeperiment not with battery above battery experiment level.
        echo "----- Uninstalling drainer app"
        "$adb_" uninstall $drainer_app_package_name_  </dev/null
    elif [  "$current_battery_level" -lt "$experiment_battery_level_" ]; then
        echo "--- Current battery is low, so we need to wait battery"
        get_battery_level "${adb_}"
        current_battery_level=$?
        echo "--- Desactivating the charge stop level option"
         
     
        if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
            echo "--- Desactivating the charge stop level option, command :  $adb_ shell echo 100 > ${charge_stop_level_file_} </dev/null"
            "$adb_" shell "echo 100 > ${charge_stop_level_file_} " </dev/null
        elif [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
            echo "--- For samsung unlocking cc_info level for exeperiments : "$adb_" shell \"su -c \'echo 0 > ${charge_limit_file_dict_[$PHONE_NAME_]}\'\" </dev/null "
            "$adb_" shell "su -c 'echo 1 > ${charge_limit_file_dict_[$PHONE_NAME_]}'" </dev/null
        fi  

        #"$adb_" shell "echo schedutil > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_governor  " </dev/null
        while [ "$current_battery_level" -lt "$experiment_battery_level_" ]; do
            echo -e "--- The current battery level : ${current_battery_level}, still lower than the experiment one :  $experiment_battery_level_ \n--- Waiting 30 second..."
            sleep 30
            get_battery_level "${adb_}"
            current_battery_level=$?
        done
        if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
            echo "--- Reactivating the charge stop level, command  "$adb_" shell "echo ${experiment_battery_level_}  > ${charge_stop_level_file_}" </dev/null"
            "$adb_" shell "echo ${experiment_battery_level_}  > ${charge_stop_level_file_}" </dev/null
            echo "--- Current battery is now equal to the experiment battery level"
        fi
    fi

    if [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
        echo "--- For samsung stabilizing cc_info level for exeperiments : "$adb_" shell \"su -c \'echo 0 > ${charge_limit_file_dict_[$PHONE_NAME_]}\'\" </dev/null "
        "$adb_" shell "su -c 'echo 0 > ${charge_limit_file_dict_[$PHONE_NAME_]}'" </dev/null
    fi

}



function reset_cpu_configuration(){
    echo "--- Resetting all frequency configurations"
    adb_=$1
    phone_system_cpu_folder_=$2
    PHONE_NAME_=$3
    for i in {1..7}; do
        echo " -- Command used : echo schedutil > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_governor  "

        if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ];  then
            "$adb_" shell "echo schedutil > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_governor" </dev/null
        elif  [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then
           "$adb_" shell "su -c 'echo interactive > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_governor'" </dev/null  # WARNING BE SURE TO PUT ''
        fi 

      
    done
}


function get_frequency_from_core(){
    core_indice=$1 # the behaviour of this function depends on the phone name passed as parameter
                   # This function will interpret the relationship between core indice and socket type using the phone name and the global dictionnary variable.
    core_frequency_level=$2
    PHONE_NAME_=$3
    result_="33"

    if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then
    
        #echo "in function get_frequency_from_core , core indice = $1, core level = $2"
        if [ $core_indice -ge "0" ] && [ $core_indice -lt "6" ]; then
            #echo "core indice between 0 and 6, exact frequency: ${freq_dict_of_little_socket_google_pixel[$core_frequency_level]} "
            result_=${freq_dict_of_little_socket_google_pixel[$core_frequency_level]}
        elif  [ $core_indice -eq "6" ]; then 
            #echo "core indice is 6, exact frequency: ${freq_dict_of_medium_socket_google_pixel[$core_frequency_level]} "
            result_=${freq_dict_of_medium_socket_google_pixel[$core_frequency_level]}
        elif  [ $core_indice -eq "7" ]; then 
            #echo "core indice is 7, exact frequency:  ${freq_dict_of_big_socket_google_pixel[$core_frequency_level]} "
            result_=${freq_dict_of_big_socket_google_pixel[$core_frequency_level]}
        fi
        #echo "Before return result = $result_"

    elif [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then
        #echo "in function get_frequency_from_core , core indice = $1, core level = $2"
        if [ $core_indice -ge "0" ] && [ $core_indice -lt "4" ]; then
            #echo "core indice between 0 and 6, exact frequency: ${freq_dict_of_little_socket_google_pixel[$core_frequency_level]} "
            result_=${freq_dict_of_little_socket_samsung_galaxy[$core_frequency_level]}
        elif  [ $core_indice -ge "4" ]  && [ $core_indice -lt "8" ]; then 
            #echo "core indice is 6, exact frequency: ${freq_dict_of_medium_socket_google_pixel[$core_frequency_level]} "
            result_=${freq_dict_of_big_socket_samsung_galaxy[$core_frequency_level]}
        fi
    fi

    echo $result_  # bacause this value is larger than 255, we just echo it, without echoing enything else; 
}


function set_core_frequency(){
    adb_=$1
    configuration_to_test_=$2
    phone_system_cpu_folder_=$3
    PHONE_NAME_=$4

    
    IFS=',' read -r -a configurations_array <<< "$configuration_to_test_"
    for  i in ${!configurations_array[@]};  
    do
        echo "--- Frequency level of core $i is  ${configurations_array[$i]}"
        frequency_level=${configurations_array[$i]}

        # handling case where the governor is not changed (frequency level = 4)
        # we suppose that the frequency level of active cores are the same;
        if [ $frequency_level -eq "4" ];  then
            echo "--- Modifying the governor of core $i to set the default value"
            if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ];  then
                echo "--- Modifying the governor of core $i "
                "${adb_}" shell "echo schedutil > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_governor  "   </dev/null
            elif  [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then
                echo "--- Modifying the governor of core $i "
                "${adb_}" shell "su -c 'echo interactive > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_governor'  "   </dev/null
            fi 
        else
            exact_value_of_frequency_=$(get_frequency_from_core "$i" "$frequency_level" $PHONE_NAME_)
            echo "--- Exact frequency of core  $i:  $exact_value_of_frequency_"
            

            if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ];  then
                echo "--- Modifying the governor of core $i "
                "${adb_}" shell "echo userspace > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_governor  "   </dev/null
                echo "--- Modifying the the current frequency of core $i with frequency $exact_value_of_frequency_"
                "${adb_}" shell "echo $exact_value_of_frequency_ > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_setspeed  " </dev/null        
            elif  [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then
                echo "--- Modifying the governor of core $i "
                "${adb_}" shell "su -c 'echo userspace > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_governor'  "   </dev/null
                echo "--- Modifying the the current frequency of core $i with frequency $exact_value_of_frequency_"
                "${adb_}" shell "su -c 'echo $exact_value_of_frequency_ > ${phone_system_cpu_folder_}${i}/cpufreq/scaling_setspeed' " </dev/null
            fi 
        fi  
    done

}

function calibrate_monsoon_power_meter(){
    echo "--- Calibrating Monsoon power meter, please wait for $4 seconds..."
    python_exe_=$1
    monson_power_meter_script_=$2
    monsonn_output_voltage_=$3
    calibration_duration_=$4
    csv_output_file_=$5

    
    cmd.exe /c  "${python_exe_}"  ${monson_power_meter_script_}  1 $monsonn_output_voltage_ $calibration_duration_ $csv_output_file_  
    echo "--- Monsoon power meter Calibrated"
}

function start_powermeter_sampling(){
    echo "--- Sampling with the Monsoon power meter"
    python_exe_=$1
    monson_power_meter_script_=$2
    monsonn_output_voltage_=$3
    experiment_duration_=$4
    csv_output_file_=$5
    powermeter_summary_output_file_=$6

    
    cmd.exe /c  "${python_exe_}"  ${monson_power_meter_script_}  2 $monsonn_output_voltage_ $experiment_duration_ $csv_output_file_ $powermeter_summary_output_file_
    echo "--- Monsoon power meter sampling is finished !"
}

function start_benchmarking_app(){

    adb_=$1
    sdcard_path_in_phone_=$2
    experiment_folder_name_inside_the_phone_=$3
    current_configuration_file_name_inside_the_phone_=$4
    configuration_to_test_=$5
    current_app_output_folder_inside_the_phone_=$6
    experiment_app_package_name_=$7
    EXPERIMENT_APK_PATH__WINDOWS_SYNTAX_=$8
    experiment_app_main_activity_=$9
    experiment_duration_=${10}
    current_experiment_duration_file_name_inside_the_phone_=${11}


    echo "##  writing the configuration inside the phone file"
    echo " --- Removing file  ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_} "
     if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ];  then
        "$adb_" shell "rm -rfv ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}"  </dev/null
     elif  [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then
        "$adb_" shell "rm -rf ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}"  </dev/null
     fi 
   
    
    echo " --- Clearing the logcat  "
    "$adb_" logcat -c  </dev/null

    echo " --- Creating file  ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}"
    "$adb_" shell "mkdir ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}"  </dev/null

    "$adb_" shell "touch ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_configuration_file_name_inside_the_phone_}" </dev/null
    "$adb_" shell "echo ${configuration_to_test_} >  ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_configuration_file_name_inside_the_phone_}" </dev/null
    "$adb_" shell "echo ${experiment_duration_} >  ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_experiment_duration_file_name_inside_the_phone_}" </dev/null

    "$adb_" shell "mkdir  ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_app_output_folder_inside_the_phone_}" </dev/null


    # starting the experiment apk
    echo "----- Uninstalling experiment app"
    "$adb_" uninstall $experiment_app_package_name_  </dev/null
    echo "----- Installing experiment  app"
    "$adb_" install "$EXPERIMENT_APK_PATH__WINDOWS_SYNTAX_" </dev/null

    echo "------ Giving rights to experiment app"
    "$adb_" shell pm grant $experiment_app_package_name_  android.permission.DUMP   </dev/null
    "$adb_" shell pm grant $experiment_app_package_name_ android.permission.PACKAGE_USAGE_STATS  </dev/null
    "$adb_" shell pm grant $experiment_app_package_name_ android.permission.WRITE_EXTERNAL_STORAGE </dev/null
    "$adb_" shell pm grant $experiment_app_package_name_ android.permission.READ_EXTERNAL_STORAGE </dev/null

    echo "----- Starting experiment app"
    "$adb_" shell  "sleep 1
        am start -n $experiment_app_package_name_/$experiment_app_main_activity_" </dev/null

    sleep 4
    echo "adb command :   ps -A | grep $experiment_app_package_name_"
    EXPERIMENT_APP_PID=$("$adb_" shell "ps -A | grep $experiment_app_package_name_" </dev/null | awk '{ print $2 }')
    EXPERIMENT_APP_PID=$(echo $EXPERIMENT_APP_PID | tr -d '\r') # To remove the DOS carriage return (^M). 
    echo " ----- Experiment app started with pid: $EXPERIMENT_APP_PID "

}


function save_cc_info_data(){
    adb=$1
    starting_or_ending=$2
    cc_info_file_path_inside_the_phone_=$3
    tmp_experiment_folder_path_=$4

    if [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then 
        current_cc_info_level_=$("${adb_}" shell "cat ${cc_info_file_path_inside_the_phone_}" </dev/null )
        current_cc_info_level_=$(echo $current_cc_info_level_ | tr -d '\r') # To remove the DOS carriage return (^M). 
        echo "--- Current cc_info level : ${current_cc_info_level_} , cc_info file in phone: $cc_info_file_path_inside_the_phone_"
        echo ${current_cc_info_level_} > "${tmp_experiment_folder_path_}/${starting_or_ending}_cc_info.txt" 
    fi

}


function wait_for_app_threads_to_be_in_experiment_phase(){
    adb_=$1
    configuration_to_test_=$2
    sdcard_path_in_phone_=$3
    experiment_folder_name_inside_the_phone_=$4
    current_app_output_folder_inside_the_phone_=$5
    cc_info_file_path_inside_the_phone_=$6
    tmp_experiment_folder_path_=$7

    number_of_cores_to_occupy=0
    IFS=',' read -r -a configurations_array <<< "$configuration_to_test"
    for  i in ${!configurations_array[@]};  
    do
        frequency_level=${configurations_array[$i]}
        echo "--- frequency level of core $i is  $frequency_level"
        if [ $frequency_level -ne "0" ]; then
            number_of_cores_to_occupy=$((number_of_cores_to_occupy + 1))
        fi
    done

    echo "--- Number of cores to occupy = $number_of_cores_to_occupy"

    number_of_thread_in_experiment_phase=$("${adb_}" shell "ls  ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_app_output_folder_inside_the_phone_} | wc -l"  </dev/null )
    number_of_thread_in_experiment_phase=$(echo $number_of_thread_in_experiment_phase | tr -d '\r') # To remove the DOS carriage return (^M). 
    echo "--- Number of thread in experiment phase : ${number_of_thread_in_experiment_phase} "


    while [ "$number_of_thread_in_experiment_phase" -lt "$number_of_cores_to_occupy" ]; do
           
        echo "--- The current number of thread ready to be sambled  : ${number_of_thread_in_experiment_phase}, still lower than the experiment one :  $number_of_cores_to_occupy"
        sleep 1
        number_of_thread_in_experiment_phase=$("${adb_}" shell "ls  ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_app_output_folder_inside_the_phone_} | wc -l" </dev/null )
        number_of_thread_in_experiment_phase=$(echo $number_of_thread_in_experiment_phase | tr -d '\r') # To remove the DOS carriage return (^M). 
        echo "--- Number of thread in experiment phase : ${number_of_thread_in_experiment_phase} "

    done
    echo "--- Now threads are running and the phone is ready to be sampled with the power meter \n--- Threads pids "
    "${adb_}" shell "ls ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_app_output_folder_inside_the_phone_}" </dev/null 

    echo "--- Printing cc_info beginning datas (for the samsung galaxy s8)"
    save_cc_info_data "${adb_}" "starting" "${cc_info_file_path_inside_the_phone_}" "${tmp_experiment_folder_path_}"

}




function get_number_of_threads(){
    configuration_to_test_=$1

    number_of_cores_to_occupy_=0    #Computing the Number of threads normally started
    IFS=',' read -r -a configurations_array <<< "$configuration_to_test_"
    for  i in ${!configurations_array[@]};  
    do
        frequency_level=${configurations_array[$i]}
        echo "--- frequency level of core $i is  $frequency_level"
        if [ $frequency_level -ne "0" ]; then
            number_of_cores_to_occupy_=$((number_of_cores_to_occupy_ + 1))
        fi
    done
    return $number_of_cores_to_occupy_
}

function wait_for_app_threads_to_be_ended_collect_results(){
    adb_=$1
    configuration_to_test_=$2
    sdcard_path_in_phone_=$3
    experiment_folder_name_inside_the_phone_=$4
    current_app_output_folder_inside_the_phone_=$5
    tmp_experiment_folder_path_=$6
    tmp_experiment_folder_path_windows_syntax_=$7
    cc_info_file_path_inside_the_phone_=$8

    number_of_cores_to_occupy_=0    #Computing the Number of threads normally started
    IFS=',' read -r -a configurations_array <<< "$configuration_to_test_"
    for  i in ${!configurations_array[@]};  
    do
        frequency_level=${configurations_array[$i]}
        echo "--- frequency level of core $i is  $frequency_level"
        if [ $frequency_level -ne "0" ]; then
            number_of_cores_to_occupy_=$((number_of_cores_to_occupy_ + 1))
        fi
    done
    ### Verifying  the number of file notifying the end of expermiment from app.
    echo "--- Number of threads normally started = $number_of_cores_to_occupy_"  
    number_of_threads_ended=$("${adb_}" shell "ls  ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_app_output_folder_inside_the_phone_} | grep _ended | wc -l"  </dev/null )
    number_of_threads_ended=$(echo $number_of_threads_ended | tr -d '\r') # To remove the DOS carriage return (^M). 
    echo "--- Number of thread ended: ${number_of_threads_ended} "

    while [ "$number_of_threads_ended" -lt "$number_of_cores_to_occupy_" ]; do
            
        echo "--- The current number of thread ended   : ${number_of_threads_ended}, still lower than the number of threads normally started :  $number_of_cores_to_occupy_"
        sleep 1
        number_of_threads_ended=$("${adb_}" shell "ls  ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_app_output_folder_inside_the_phone_} | grep _ended | wc -l"  </dev/null )
        number_of_threads_ended=$(echo $number_of_threads_ended | tr -d '\r') # To remove the DOS carriage return (^M). 
        echo "--- Number of thread ended : ${number_of_threads_ended} "
    done
    echo "--- Now threads are stopped, getting the cc_info_level for samsung "
    save_cc_info_data "${adb_}" "ending" "${cc_info_file_path_inside_the_phone_}" ${tmp_experiment_folder_path_}


    echo "---  Copying thread results locally "
    echo "command "${adb_}" pull ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_app_output_folder_inside_the_phone_} ${tmp_experiment_folder_path_windows_syntax_} </dev/null "
    "${adb_}" pull ${sdcard_path_in_phone_}/${experiment_folder_name_inside_the_phone_}/${current_app_output_folder_inside_the_phone_} ${tmp_experiment_folder_path_windows_syntax_} </dev/null 
    echo "saving the logcat file to  ${tmp_experiment_folder_path_} -$6-"
    "${adb_}" logcat -d > ${tmp_experiment_folder_path_}/logcat_output </dev/null 
}

TESTING_UTILS_SOURCING=" ... utils.sh correctly loaded"

