#!/usr/bin/bash



# Tool to automatically clean a result folder in which in the configuration_tmp_folder/app_output folder we saved data from thread coming from previous experiement. 
# They are file with indices greather than the number of thread (number of lines of all_workload file)
PROJECT_PATH="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization"
SCRIPT_PATH="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused"
#SUMMARY_FOLDER="$SCRIPT_PATH/RESULT_FOLDER_EXAMPLE"
SUMMARY_FOLDER="$PROJECT_PATH/FIRST_RESULTS"
echo "--- Walking through directory $SUMMARY_FOLDER"

for current_configuration_directory in  $SUMMARY_FOLDER/*/ ; do
    echo "--- Processing configutation directory $current_configuration_directory"
    current_app_output_folder=$current_configuration_directory/app_output_folder
    echo "--- Processing app_output folder $current_app_output_folder"
    number_of_threads=$(cat ${current_app_output_folder}/all_workloads.txt | wc -l)
    echo "--- Real number of threads $number_of_threads"

    number_of_thread_folders=$(ls ${current_app_output_folder} | grep "ready_for_sampling" | wc -l)
    echo "--- Number of threads folders $number_of_thread_folders"
    echo "--- Number of unecessary threads $[ number_of_thread_folders-number_of_threads ]"
    

    for i in  $(seq $number_of_threads $[ number_of_thread_folders-1 ]); do     
        echo "--- Removing file ${current_app_output_folder}/Thread_${i}_ready_for_sampling"
        rm  ${current_app_output_folder}/Thread_${i}_ready_for_sampling
        echo "--- Removing file  ${current_app_output_folder}/Thread_${i}_ended"
        rm  ${current_app_output_folder}/Thread_${i}_ended 
    done

done

# replacing expermiment by experiment in the name of directories
for current_configuration_directory in  $SUMMARY_FOLDER/*/ ; do
    echo "--- Processing configutation directory $current_configuration_directory"
    new_path_name=$(echo $current_configuration_directory | sed "s/expermiment/experiment/") 
    echo  -e "--- New path name $new_path_name \n--- Moving directory:"
    mv $current_configuration_directory $new_path_name
    
done



