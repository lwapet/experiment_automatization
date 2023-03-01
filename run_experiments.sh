#!/usr/bin/bash
# scritp to run experiments automatically
## NOTE : This code version is for google pixel 4a 5g
## After modifying configuration after line 36 Use this command to run experiment:  bash run_experiments.sh | tee -a experiment_log_file.txt  
##                                                                                   where experiment_log_file.txt is the variable $experiment_log_file (see below)
# some paths configurations
PROJECT_PATH="/mnt/c/Users/lavoi/opportunist_task_on_android/experiment_automatization"
PROJECT_PATH_WINDOWS_SYNTAX="C:\Users\lavoi\opportunist_task_on_android\experiment_automatization"
APK_PATH__WINDOWS_SYNTAX="C:\Users\lavoi\opportunist_task_on_android\benchmarking_tools\benchmarking_app_to_test_big_cores\app\debug\app-debug.apk"
DRAINER_APK_PATH__WINDOWS_SYNTAX="C:\Users\lavoi\opportunist_task_on_android\benchmarking_tools\app_to_drain_battery.apk"
drainer_app_package_name="com.opportunistask.scheduling.benchmarking_app_to_test_big_cores"
drainer_app_main_activity="com.opportunistask.scheduling.benchmarking_app_to_test_big_cores.MainActivity"
adb='/mnt/c/Program Files/Android/platform-tools_r33.0.1-windows/platform-tools/adb.exe'
monkeyrunner_bat='C:\Users\lavoi\AppData\Local\Android\Sdk\tools\bin\monkeyrunner.bat'
ANDROID_SWT="C:\\Users\\lavoi\\AppData\\Local\\Android\\Sdk\\tools\\lib"
monkey_runner_script="${PROJECT_PATH_WINDOWS_SYNTAX}\monkey_runner.py"
experiment_battery_level=100 # for samsung galaxy s8 the experiment battery level is 100 because of a technical limation
                            # We cannot  automaticall reduce the level of battery on samsung as on google pixel. 
                            # On google pixel, to reduce the level to 50% when it is 57% , 
                            # we set the charge_limit file to 10 and start the drainer app. And then, when it reaches 50, we restaure the charge_litmit to 100. 
                            # Internally, it seems like the phone firstly uses the battery energy to make it reach 10%
                            # But on samsung, there is no functionnal file to mimic the charge_limit functionnality. 
                            # And more than that when we set the hv_charger_stop, the battery is not charged but it is not also used by app, so cannot be reduced. 

                            # So what this script does does for the samsung is to always consider 100 as the experiment_battery_level
                            # The battery level cannot be above this level
                            # When the battery is under this level , the script wait as in it is done on google pixel and when the level is okay 
                            # it set the hv_charger_stop to 0, to stabilize cc_info (make it not to increase)
                            # And we still use the cc_info  variation because it can decrease, when applications are using battery and power supply at the same time
level_for_reducing_charging="50"
charge_stop_level_file="/sys/devices/platform/soc/soc:google,charger/charge_stop_level"
charge_limit_file_for_google_pixel="/sys/devices/platform/soc/soc\:google,battery/power_supply/battery/charge_limit"     # for the google pixel the value in this file is the level of battery targetted by the system 
                                                                                                                         # If the battery is above this level, the system apparently drain the battery first
                                                                                                                
charge_limit_file_for_samsung_galaxy="/sys/devices/platform/battery/power_supply/battery/hv_charger_set" # For the samsung galaxy file, 
                                                                         # we suspect that this file wich can contains 0 or 1, 
                                                                         # simpling put the battery out of the circuit (when the phone is connected-wich is the context of this experiement). 
                                                                         # the battery is not charged and it is normally longer used by applications
                                                                         # But if the application consume a lot of energy it will reuse the battery, theses cases are rare, 
                                                                         


declare -A charge_limit_file_dict
charge_limit_file_dict["samsung_galaxy_s8"]=$charge_limit_file_for_samsung_galaxy
charge_limit_file_dict["google_pixel_4a_5g"]=$charge_limit_file_for_google_pixel

cc_info_file_path_inside_the_phone="/sys/devices/platform/battery/power_supply/battery/cc_info"
phone_system_cpu_folder="/sys/devices/system/cpu/cpu"


experiment_log_file_name="experiment_log_file.txt"
experiment_log_file="${PROJECT_PATH}/$experiment_log_file_name"
summary_files_only_folder="${PROJECT_PATH}/summary_files_only"
experiment_output_folder="${PROJECT_PATH}/output_folder"
tmp_experiment_folder_name="last_tmp_expermiment_folder"
tmp_experiment_folder_path="${PROJECT_PATH}/$tmp_experiment_folder_name"
tmp_experiment_folder_path_windows_syntax="${PROJECT_PATH_WINDOWS_SYNTAX}\\${tmp_experiment_folder_name}"

monson_power_meter_script="C:\\Users\\lavoi\\opportunist_task_on_android\\experiment_automatization\\monsoon_power_meter.py"
monsonn_output_voltage="3.70"
tmp_csv_output_file="${tmp_experiment_folder_path_windows_syntax}\configuration_mesurement.csv"
tmp_powermeter_summary_output_file="${tmp_experiment_folder_path}/powermeter_summary.txt"
tmp_powermeter_summary_output_file_windows_syntax="${tmp_experiment_folder_path_windows_syntax}\powermeter_summary.txt"
python_exe='C:\Program Files\Python35\python.exe' 
calibration_duration=10 # in seconds


####################### CAN BE FREQUENTLY MODIFIED
# Project steps configurations
:<<'END_COMMENT'
PHONE_NAME="samsung_galaxy_s8"  # can be google_pixel_4a_5g or samsung_galaxy_s8
CLEAN_TMP_FOLDER="0"  # Normally it sould be 1
FIX_CHARGE_STOP_LEVEL="0"
VERIFY_BATTERY_LEVEL="0"
CALIBRATE_POHNE_CORE_FREQUENCY="0"
CALIBRATE_MONSOON_POWER_METER="0"
START_BENCHMARKING_APP_AND_PIN_THREADS="0"
PERFORMS_POWERMETER_SAMPLING="0"
WAIT_FOR_THREADS_AND_COLLECT_RESULTS="0"
PARSE_AND_COLLECT_CURRENT_CONFIGURATION_RESULT="1" 
OBSERVE_A_PAUSE_BETWEEN_EXPERIMENTS="1"
MOFIFY_OUTPUT_SUMMARY="1"
RESET_CHARGE_STOP_LEVEL="0"
END_COMMENT


PHONE_NAME="samsung_galaxy_s8"  # can be google_pixel_4a_5g or samsung_galaxy_s8
CLEAN_TMP_FOLDER="1"  # Normally it sould be 1
FIX_CHARGE_STOP_LEVEL="1"
VERIFY_BATTERY_LEVEL="1"
CALIBRATE_POHNE_CORE_FREQUENCY="1"
CALIBRATE_MONSOON_POWER_METER="1"
START_BENCHMARKING_APP_AND_PIN_THREADS="1"
PERFORMS_POWERMETER_SAMPLING="1"
WAIT_FOR_THREADS_AND_COLLECT_RESULTS="1"
PARSE_AND_COLLECT_CURRENT_CONFIGURATION_RESULT="1" 
OBSERVE_A_PAUSE_BETWEEN_EXPERIMENTS="1"
MOFIFY_OUTPUT_SUMMARY="1"
RESET_CHARGE_STOP_LEVEL="0"







# Other experiments configurations
experiment_duration=600 # in seconds
pause_beetwen_experiment=180 # in seconds
current_experiment_duration_file_name_inside_the_phone="experiment_duration.txt"
PROJECT_OUTPUT_PATH="${PROJECT_PATH}/output_folder"
raw_result_file="${PROJECT_OUTPUT_PATH}/raw_result.txt"
PROJECT_TRASH_FOLDER="${PROJECT_PATH}/can_be_reused/to_delete_first"
input_configurations_file="${PROJECT_PATH}/input_configurations_file.csv"
output_summary_file="$PROJECT_OUTPUT_PATH/summary.csv"   # output summary file for all experiments

####################### CAN BE FREQUENTLY MODIFIED




# Dictionnary and tested combinations configurations 
use_frequency_level="1" # if 0, the configuration contains exact values of frequency
configuration_to_test="0,0,0,0,0,1,2,3" # by default the experiment script takes into account the frequency level format, this variable varies depending on the current configuration
current_configuration_user_friendly="0-1m-1M" # This variable can vary too, if we test many configurations


# to handle exact value of frequency format where the governor is not modified, 1 KHz is add to the maximum possible value of frequency. 
# But when the automatization script configure the phone it does not modify the frequency it just set the governor value to the default one.
freq_dict_of_little_socket_google_pixel=([0]="0" [1]="576000" [2]="1363200" [3]="1804800" [4]="1804801")
freq_dict_of_medium_socket_google_pixel=([0]="0" [1]="652800" [2]="1478400" [3]="2208000" [4]="2208001")
freq_dict_of_big_socket_google_pixel=([0]="0" [1]="806400" [2]="1766400" [3]="2400000" [4]="2400001")


freq_dict_of_little_socket_samsung_galaxy=([0]="0" [1]="598000" [2]="1248000" [3]="1690000" [4]="1690001")
freq_dict_of_big_socket_samsung_galaxy=([0]="0" [1]="741000" [2]="1469000" [3]="2314000"  [4]="2314001")



# Apk and phone configurations
sdcard_path_in_phone="/sdcard"
experiment_folder_name_inside_the_phone="experiments_automatization"
current_configuration_file_name_inside_the_phone="current_configuration.txt"
current_app_output_folder_inside_the_phone="app_output_folder"
EXPERIMENT_APK_PATH__WINDOWS_SYNTAX="C:\Users\lavoi\opportunist_task_on_android\git_repositories\benchmarking_app_to_test_big_cores\app\debug\app-debug.apk"
experiment_app_package_name="com.opportunistask.scheduling.benchmarking_app_to_test_big_cores"
experiment_app_main_activity="com.opportunistask.scheduling.benchmarking_app_to_test_big_cores.MainActivity"




# Loading libraries
echo "--- Loading utils.sh library .... "
sleep 1
source ${PROJECT_PATH}/utils.sh
echo "---  $TESTING_UTILS_SOURCING"

echo "--- Loading parsing_utils.sh library .... "
sleep 1
source ${PROJECT_PATH}/parsing_utils.sh
echo "---  $TESTING_PARSING_UTILS_SOURCING"

echo "--- Loading experiment_process_for_a_single_configuration.sh library .... "
sleep 1
source ${PROJECT_PATH}/experiment_process_for_a_single_configuration.sh
echo "---  $TESTING_SINGLE_EXPERIMENT_PROCESS_SOURCING"



if [ "$FIX_CHARGE_STOP_LEVEL" -ne "0" ]; then
    ## First step : setting the charge stop level value
    if [ "$PHONE_NAME" = "google_pixel_4a_5g" ];  then
        echo "--- First step : setting the charge stop level value"
        "${adb}" root
        "$adb" shell "echo ${experiment_battery_level} > ${charge_stop_level_file}"
    fi     
fi




# This code is to test is if the input file don't have a correct input format with 5 column (please see far below)
# this function replace the provided input file with a correct one, 
# The provided input file should have tow columns : configurations,google pixel format,
#                            for human readable format and google pixel one
# NOTE: JUST COPY AND PASTE THE HEADER (after removing "# "), MAINTAINS EVEN THE SAME SPACES IN DATAS
# configurations,google pixel format
# idle,[0- 0- 0- 0- 0- 0- 0- 0]
# 1-0,[3- 0- 0- 0- 0- 0- 0- 0]
if [ "$PHONE_NAME" = "google_pixel_4a_5g" ];  then
    phone_format_header_in_file="google pixel format"
elif  [ "$PHONE_NAME" = "samsung_galaxy_s8" ]; then
    phone_format_header_in_file="samsung galaxy format"
fi 




while IFS= read -r line; do
    line=$(echo $line | tr -d '\r')
    first_column=$(echo -e  $line   | cut -d ',' -f 1 )
    second_column=$(echo -e  $line   | cut -d ',' -f 2 )
    if [ "$first_column" = "configurations" ] && [ "$second_column" = "${phone_format_header_in_file}" ]; then    
        echo "--- The configuration file does not have the suitable format, we save it to and replace with the correct one"
        sleep 2
        echo "--- Before move command mv $input_configurations_file  ${input_configurations_file::-4}__no_suitable_format"
        #cp $input_configurations_file ${input_configurations_file::-4}__no_suitable_format.csv  # we remove the extention
        echo "--- After move command "

        produce_suitable_input_file_from_human_readable_and_phone_format  ${input_configurations_file} ${input_configurations_file::-4}__finally_used.csv "${PROJECT_TRASH_FOLDER}" "${PHONE_NAME}"
        echo "--- Suitable format produced"
        input_configurations_file=${input_configurations_file::-4}__finally_used.csv

        break
    elif [ "${line:0:83}" = "configurations,generic format,exact frequency,${phone_format_header_in_file},exact frequencies" ]; then   
        echo "--- The configuration file has the suitable format, we use it"
        sleep 2
        break
    fi
done < "$input_configurations_file"
echo $result






#Looping on all configurations
# as input the script takes a list of configuration with this format (Note: the header should be present, the user friendly format has no hooks, others has hooks no brakets no braces )

# The script above is used to genarate this file from  a file with only  configurations+phone_format as header 
# but for now the long format below is used as it is suppose to be the same used by the plotter and by the model.
# Why this format, because the first code to produce it wrote it like that, it was python with internal np and list library. 
# configurations,generic format,exact frequency,google pixel format,exact frequencies
# idle,[0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0],[0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0],[0- 0- 0- 0- 0- 0- 0- 0],[0- 0- 0- 0- 0- 0- 0- 0]
# 1-0,[3- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0],[1804800- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0],[3- 0- 0- 0- 0- 0- 0- 0],[1804800- 0- 0- 0- 0- 0- 0- 0]
# 2-0,[3- 3- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0],[1804800- 1804800- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0],[3- 3- 0- 0- 0- 0- 0- 0],[1804800- 1804800- 0- 0- 0- 0- 0- 0]
# 3-0,[3- 3- 3- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0],[1804800- 1804800- 1804800- 0- 0- 0- 0- 0- 0- 0- 0- 0- 0],[3- 3- 3- 0- 0- 0- 0- 0],[1804800- 1804800- 1804800- 0- 0- 0- 0- 0]
is_header=1
while IFS=, read  -r configurations generic_format exact_frequency_generic phone_format exact_frequency_phone; do
    
    if [ "$is_header" -ne "0" ]; then
        echo "--- Reading header $configurations and $exact_frequency_phone" # we don't consider the header
        is_header=0
    else 

        configuration_to_test=${phone_format:1:-1} # removing first and last hooks
        configuration_to_test=$(echo "$configuration_to_test" | sed 's/ //g' | sed 's/-/,/g' ) # removing spaces and replacing dashes by commas
        current_configuration_user_friendly=$configurations
        echo "--- Performing experiments on configuration $current_configuration_user_friendly"
        sleep 2
        

        perform_experiment_for_one_configuration $configuration_to_test $current_configuration_user_friendly $PHONE_NAME_
  

        echo "--- Obtaining experiment summary result to add to result folder"
        experiment_results=$(read_all_file_line_by_line "${tmp_experiment_folder_path}/energy_power_workload_energyByWorkload_ccInfo")
        
        energy_=$(echo -e  $experiment_results   | grep "Consumed Energy" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
        echo "--- Experiment result, Energy consumed = $energy_"
        avg_power_=$(echo -e $experiment_results | grep "Avg power" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
        echo "--- Experiment result, Avg Power = $avg_power_"
        total_workload_=$(echo -e $experiment_results | grep "Total Workload" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
        echo "--- Experiment result, Total Workload = $total_workload_"
        energy_efficiency_=$(echo -e $experiment_results | grep "Energy Efficiency" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
        echo "--- Experiment result, Energy Efficiency = $energy_efficiency_"
        echo "--- Adding result to summary file" 
        exact_frequency_phone=$(echo $exact_frequency_phone |   tr -d '\r' )
        starting_cc_info_=$(echo -e $experiment_results | grep "Starting cc_info" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
        echo "--- Starting cc information : $starting_cc_info_ " 
        ending_cc_info_=$(echo -e $experiment_results | grep "Ending cc_info" | cut -d ':' -f 2 | sed 's/ //g' |  tr -d '\r')
        echo "--- Ending cc information : $ending_cc_info_" 


    
        if [ "$MOFIFY_OUTPUT_SUMMARY" -ne "0" ]; then
            if [ -f "$output_summary_file" ]; then
                echo "--- The file $output_summary_file exists we just appending the result to the file"
                echo "$configurations,$generic_format,$exact_frequency_generic,$phone_format,$exact_frequency_phone,$energy_,$avg_power_,$total_workload_,$energy_efficiency_,$starting_cc_info,$ending_cc_info" >> $output_summary_file
            else
                echo "--- The file $output_summary_file does not exist  we create it and add header"
                touch $output_summary_file
                echo "configurations,generic format,exact frequency,${phone_format_header_in_file},exact frequencies,phone energy,phone power,workload,energy by workload,starting cc_info,ending cc_info" > $output_summary_file
                echo "$configurations,$generic_format,$exact_frequency_generic,$phone_format,$exact_frequency_phone,${energy_},$avg_power_,$total_workload_,$energy_efficiency_,$starting_cc_info,$ending_cc_info" >> $output_summary_file
            fi      
        else
            if [ -f "${output_summary_file}_newly_added" ]; then
                echo "--- The file ${output_summary_file}_newly_added exists we just appending the result to the file"
                echo "$configurations,$generic_format,$exact_frequency_generic,$phone_format,$exact_frequency_phone,$energy_,$avg_power_,$total_workload_,$energy_efficiency_,$starting_cc_info,$ending_cc_info" >>  ${output_summary_file}_newly_added 
            else
                echo "--- The file  ${output_summary_file}_newly_added  does not exist  we create it and add header"
                touch  ${output_summary_file}_newly_added 
                echo "configurations,generic format,exact frequency,${phone_format_header_in_file},exact frequencies,phone energy,phone power,workload,energy by workload,starting cc_info,ending cc_info" >  ${output_summary_file}_newly_added 
                echo "$configurations,$generic_format,$exact_frequency_generic,$phone_format,$exact_frequency_phone,${energy_},$avg_power_,$total_workload_,$energy_efficiency_,$starting_cc_info,$ending_cc_info" >>  ${output_summary_file}_newly_added 
            fi 
        fi
        
        

        echo "--- Experiments performed on configuration $configurations."
        if [ "$OBSERVE_A_PAUSE_BETWEEN_EXPERIMENTS" -ne "0" ]; then
            date="$(date +'%d%h%y_%H_%M_%S')"
            echo "--- Observing a pause betwenn experiment; pause duration : $pause_beetwen_experiment seconds; starting at $date"
            sleep $pause_beetwen_experiment         
        fi
    fi
    #echo "--- Experiments performed on configuration $phone_format."
done < $input_configurations_file

if [ "$RESET_CHARGE_STOP_LEVEL" -ne "0" ]; then
        ## Last step : resetting the charge stop level value
        echo "--- Last step : re-setting the charge stop level value to -1"
        "${adb}" root
        "$adb" shell "echo 100 > ${charge_stop_level_file}"

        if [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
            echo "--- For make the battery able to be charged: "$adb_" shell \"su -c \'echo 1 > ${charge_limit_file_dict_[$PHONE_NAME_]}\'\" </dev/null "
            "$adb_" shell "su -c 'echo 1 > ${charge_limit_file_dict_[$PHONE_NAME_]}'" </dev/null
        fi
fi

cp $experiment_log_file ${experiment_output_folder}/$experiment_log_file_name
cp $output_summary_file ${summary_files_only_folder}/summary___$(date +'%d%h%y_%H_%M_%S').csv

### TO DO : Add exit code on functions in case of error to stop all experiments 
:<<'END_COMMENT'
END_COMMENT







# I used cmd to run a .bat script from linux wsl, and also .exe commands that do not properly works on wsl when simply called with their linux/like path. 
#cmd.exe /c  "${monkeyrunner_bat}" C:\Users\lavoi\opportunist_task_on_android\scripts_valuable_files\experiment_automatization\monkey_runner.py  1 com.opportunistask.scheduling.benchmarking_app_to_test_big_cores com.opportunistask.scheduling.benchmarking_app_to_test_big_cores.MainActivity "
#cmd.exe /V /C "set ANDROID_SWT="C:\\Users\\lavoi\\AppData\\Local\\Android\\Sdk\\tools\\lib"&& "${monkeyrunner}" C:\Users\lavoi\opportunist_task_on_android\scripts_valuable_files\experiment_automatization\monkey_runner.py  1 com.opportunistask.scheduling.benchmarking_app_to_test_big_cores com.opportunistask.scheduling.benchmarking_app_to_test_big_cores.MainActivity "
#cmd.exe /c  "${python_exe}" C:\\Users\\lavoi\\opportunist_task_on_android\\scripts_valuable_files\\experiment_automatization\\test_python_call.py
#cmd.exe /V /C "set ANDROID_SWT="${ANDROID_SWT}"&& "${monkeyrunner_bat}" ${monkey_runner_script}  1 com.opportunistask.scheduling.benchmarking_app_to_test_big_cores com.opportunistask.scheduling.benchmarking_app_to_test_big_cores.MainActivity "
