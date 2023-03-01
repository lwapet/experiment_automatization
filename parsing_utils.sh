#!/usr/bin/bash

function read_all_file_line_by_line(){ # to read line by line a file, there was a problem when printing the hole file
                                       # after using the "cat" command, I had to remove \r dos in all line, 
                                       # and it was not easy to replace them with \n directly with one comman
        input=$1
        result=""
        while IFS= read -r line; do
            line=$(echo $line | tr -d '\r')
            result="${result}$line \n"
        done < "$input"
        echo $result
}

function echo_array(){
    arrVar=("$@")
    result="("
    for value in "${arrVar[@]}";do
        result=${result}$value","
    done
    result=${result::-1}")"
    echo $result
}

function echo_csv_array(){
    arrVar=("$@")
    result="["
    for value in "${arrVar[@]}";do
        result=${result}$value"- "
    done
    result=${result::-2}"]"
    echo $result
}


function echo_configuration_with_exact_value_of_frequencies(){
    configuration_to_test_=$1
    PHONE_NAME_=$2

    # getting exact values of frequencies
    current_configuration_with_exact_frequencies=()
    exact_value_of_frequency_="0"
    IFS=',' read -r -a configurations_array <<< "$configuration_to_test_"
    for  i in ${!configurations_array[@]};  
    do
        #echo "frequency level of core $i is  ${configurations_array[$i]}"
        frequency_level=${configurations_array[$i]}
        exact_value_of_frequency_=$(get_frequency_from_core "$i" "$frequency_level" "$PHONE_NAME_")
        #echo " --- adding this frequency $exact_value_of_frequency_ to configuration "
        current_configuration_with_exact_frequencies+=($exact_value_of_frequency_)
        #echo "current configuration : $(echo_array ${current_configuration_with_exact_frequencies[@]})"  # how to pass an array as parameter
    done
    echo_csv_array ${current_configuration_with_exact_frequencies[@]}
    
}

function compute_number_of_threads(){
    configuration_to_test_=$1

    number_of_cores_to_occupy_=0    #Computing the Number of threads normally started
    IFS=',' read -r -a configurations_array <<< "$configuration_to_test_"
    for  i in ${!configurations_array[@]};  
    do
        frequency_level=${configurations_array[$i]}
        #echo "--- In function compute_number_of_threads frequency level of core $i is  $frequency_level"
        if [ $frequency_level -ne "0" ]; then
            number_of_cores_to_occupy_=$((number_of_cores_to_occupy_ + 1))
        fi
    done
    #echo "  In function compute_number_of_thread,  result: $number_of_cores_to_occupy_ "
    return $number_of_cores_to_occupy_
}


function print_cc_info(){
    tmp_experiment_folder_path_=$1
    starting_or_ending=$2
    if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then
        result="0"
    elif [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then
        result=$(cat ${tmp_experiment_folder_path_}/${starting_or_ending}_cc_info.txt)
    fi
    echo $result
}

function print_total_energy(){
    powermeter_summary=$1
    PHONE_NAME_=$2
    tmp_experiment_folder_path_=$3
    current_app_output_folder_inside_the_phone_=$4
    configuration_to_test_=$5
    project_trash_folder_=$6

    energy_from_powermeter=$(echo -e $powermeter_summary | grep "Consumed Energy (mAh)" | cut -d ':' -f 2 | sed 's/ //g')
    #echo "energy from power meter  $energy_from_powermeter "
    if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then
        echo "$energy_from_powermeter"
    elif [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then

        app_output_folder="${tmp_experiment_folder_path_}/$current_app_output_folder_inside_the_phone_"
        starting_cc_info=0
        ending_cc_info=0
        compute_number_of_threads "${configuration_to_test_}"
        number_of_threads=$?
        #echo "--- Number of threads = $number_of_threads"
        ##### TO DO: TEST BOTH TO SEE
        if [ "$number_of_threads" -eq "0" ]; then

            starting_cc_info=$(cat ${tmp_experiment_folder_path_}/starting_cc_info.txt)
            ending_cc_info=$(cat ${tmp_experiment_folder_path_}/ending_cc_info.txt)
            
            
            energy=$(bc <<< "scale=3; $energy_from_powermeter - $ending_cc_info + $starting_cc_info")

        else
            for i in  $(seq 0 $[ number_of_threads-1 ]); do
               
                thread_ended=$(read_all_file_line_by_line ${app_output_folder}/Thread_${i}_ended)
                starting_cc_info=$(echo -e $thread_ended | grep "Cc_info at the beginning" | cut -d ':' -f 2 | sed 's/ //g')
                starting_cc_info=${starting_cc_info::-3}
                #echo -e " cc_info begin --- : $starting_cc_info "

                ending_cc_info=$(echo -e $thread_ended | grep "Cc_info at the end" | cut -d ':' -f 2 | sed 's/ //g')
                ending_cc_info=${ending_cc_info::-3}
                #echo -e " cc_info end --- : $ending_cc_info "

                #energy=$[energy_from_powermeter - ending_cc_info + starting_cc_info]
                energy=$(bc <<< "scale=3; $energy_from_powermeter - $ending_cc_info + $starting_cc_info")
                break
            done

        fi
        echo $energy    
    fi  
    
}






function print_thread_summary(){
    tmp_experiment_folder_path_=$1
    current_app_output_folder_inside_the_phone_=$2
    configuration_to_test_=$3
    project_trash_folder_=$4

    app_output_folder="${tmp_experiment_folder_path_}/$current_app_output_folder_inside_the_phone_"
    threads_results_string=""
    compute_number_of_threads "${configuration_to_test_}"
    number_of_threads=$?
    #echo "--- Number of threads = $number_of_threads"
    for i in  $(seq 0 $[ number_of_threads-1 ]); do
        #echo "--- Creating thread result string of thread $i"
        thread_ready_for_sampling=$(read_all_file_line_by_line ${app_output_folder}/Thread_${i}_ready_for_sampling)
        #echo -e "--- thread ready for sampling file content: \n $thread_ready_for_sampling"
        tmp_file_of_valuable_lines_begin=${tmp_experiment_folder_path_}/tmp_file_of_valuable_lines_begin
        tmp_file_of_valuable_lines_end=${tmp_experiment_folder_path_}/tmp_file_of_valuable_lines_end

        thread_ready_for_sampling_begin=$(head -n 1 ${app_output_folder}/Thread_${i}_ready_for_sampling) 
        thread_ready_for_sampling_begin="${thread_ready_for_sampling_begin#?}" # to remove the space at the beginning of the string
        nline_thread_ready=$(cat ${app_output_folder}/Thread_${i}_ready_for_sampling | wc -l)
        valuable_nline=$(( $nline_thread_ready - 1 ))
        tail -n $valuable_nline ${app_output_folder}/Thread_${i}_ready_for_sampling > ${tmp_file_of_valuable_lines_begin} # To avoid considering the line with thread_id
        thread_ready_for_sampling_end=$(read_all_file_line_by_line "${tmp_file_of_valuable_lines_begin}")
        mv "${tmp_file_of_valuable_lines_begin}" ${project_trash_folder_}/tmp_file_of_valuable_lines_begin_$(date +'%d%h%y_%H_%M_%S')
        #echo -e "--- Thread ended file valuable content: \n$thread_ready_for_sampling_begin \n $thread_ready_for_sampling_end"

        nline_thread_ended=$(cat ${app_output_folder}/Thread_${i}_ended | wc -l)
        valuable_nline=$(( $nline_thread_ended - 1 ))
        tail -n $valuable_nline ${app_output_folder}/Thread_${i}_ended > ${tmp_file_of_valuable_lines_end}
        thread_ended=$(read_all_file_line_by_line ${tmp_file_of_valuable_lines_end})
        mv ${tmp_file_of_valuable_lines_end} ${project_trash_folder_}/tmp_file_of_valuable_lines_end_$(date +'%d%h%y_%H_%M_%S')
        #echo -e "--- Thread ended file valuable content: \n $thread_ended"
        threads_results_string="${threads_results_string}${thread_ready_for_sampling_begin}\n----------------------------------------\n${thread_ready_for_sampling_end}${thread_ended}\n"
    done
    if [ $number_of_threads -eq "0" ]; then 
        threads_results_string="\nNo thread has been started\n----------------------------------------\n "
    fi
  
    

    echo "$threads_results_string"
}

function print_total_workload(){
    tmp_experiment_folder_path_=$1
    current_app_output_folder_inside_the_phone_=$2
    configuration_to_test_=$3
    project_trash_folder_=$4

    app_output_folder="${tmp_experiment_folder_path_}/$current_app_output_folder_inside_the_phone_"
    all_workload_file=${app_output_folder}/all_workloads.txt  # This file is used to save workloads of all threads, it is used later to do the sum and compute the total workload
    #echo "all workload file $all_workload_file"
    mv $all_workload_file ${project_trash_folder_}/all_workloads.txt_$(date +'%d%h%y_%H_%M_%S')
    touch $all_workload_file
    total_workload=0
    compute_number_of_threads "${configuration_to_test_}"
    number_of_threads=$?
    #total_workload_integer=0 # implemented to have workload as integer, but not necessary for now
    for i in  $(seq 0 $[ number_of_threads-1 ]); do
        #echo "--- Computing the workload of thread $i: \n"
        thread_ended=$(read_all_file_line_by_line ${app_output_folder}/Thread_${i}_ended)
        current_workload=$(echo -e "$thread_ended" | grep "Real workload"| cut -d '-' -f 1 | cut -d ':' -f 2 | sed 's/ //g')
        #echo "--- Current workload: $current_workload"
        echo $current_workload >> $all_workload_file   # saving workload in a file to do the sum later

        # implemented to have workload as integer, but not necessary for now
        #workload_in_integer=$(printf "%.0f\n" $current_workload)
        #total_workload_integer=$((total_workload_integer+workload_in_integer))
        #total_workload_integer=$[ total_workload_integer + workload_in_integer ]
        #echo "--- Workload of the current thread in interger format: $workload_in_integer, --- Actual sum : $total_workload_integer" 

    done
    if [ $number_of_threads -eq "0" ]; then 
        total_workload=0
    else
        total_workload=$(awk '{for (i=1; i<=NF; ++i) sum += $i} END {print sum}' $all_workload_file)
    fi
    
    # implemented to have workload as integer, but not necessary for now 
    #echo "total workload in integer format = $total_workload_integer "   
    #awk -v var1="$energy" -v var2="$total_workload_integer" 'BEGIN {printf "%.15f\n",var1/var2}'
    #awk -v var1="$energy" -v var2="$total_workload_integer" 'BEGIN {print var1/var2}'
    echo "$total_workload"
}


function build_configuration_raw_result(){
    current_configuration_user_friendly_=$1 
    configuration_to_test_=$2
    configuration_with_exact_value_of_frequencies_=$3
    powermeter_summary_=$4
    threads_results_string_=$5
    energy_=$6
    total_workload_=$7
    energy_efficiency_=$8
    starting_cc_info_=$9
    ending_cc_info_=${10}

    final_result_as_string="--------------------------------------------------------------------------------\n +++++ +++++ +++++  Configuration Description\n--------------------------------------------------------------------------------\n"
    final_result_as_string="${final_result_as_string}Configuration: $current_configuration_user_friendly_ \n"
    final_result_as_string="${final_result_as_string}phone format: $configuration_to_test_ \n"
    final_result_as_string="${final_result_as_string}Exact values of frequencies: $configuration_with_exact_value_of_frequencies_ \n\n"
    final_result_as_string="${final_result_as_string}Power meter results\n------------------------------------------------------------\n"
    final_result_as_string="${final_result_as_string}$powermeter_summary_ \n"
    final_result_as_string="${final_result_as_string}Threads results\n------------------------------------------------------------\n"
    final_result_as_string="${final_result_as_string}$threads_results_string_ \n"
    final_result_as_string="${final_result_as_string}Expermiment results\n------------------------------------------------------------\n"
    final_result_as_string="${final_result_as_string}Energy Consumed (mAh): $energy_ \n"
    final_result_as_string="${final_result_as_string}Workload: $total_workload_ \n"  # use variable total_workload_integer for computations
    final_result_as_string="${final_result_as_string}Energy efficiency: $energy_efficiency_ \n"
    if [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
        final_result_as_string="${final_result_as_string}Starting cc information: $starting_cc_info \n"
        final_result_as_string="${final_result_as_string}Ending cc information: $ending_cc_info \n"
    fi
    
    final_result_as_string="${final_result_as_string}--------------------------------------------------------------------------------\n\n"
    echo "${final_result_as_string}"   # NOTE : USE "" around the string variable to correctly print starts
}



function print_generic_format_with_exact_frequencies_values(){
    configuration_in_generic_format_=$1
    PHONE_NAME_=$2
    # getting exact values of frequencies
    # 0,0,0,0,0,0,   1,0,0,   0,0,0,0  -> 0,0,0,0,0,0,   freq_from_dict__minimum_for_medium_core,0,0,   0,0,0,0
    current_configuration_with_exact_frequencies=()
    exact_value_of_frequency_="0"
    IFS=',' read -r -a configurations_array <<< "$configuration_in_generic_format_"
    for  i in ${!configurations_array[@]};  
    do
        #echo "---+ Frequency level of core $i is  ${configurations_array[$i]}"
        frequency_level=${configurations_array[$i]}
        exact_value_of_frequency_=0
        if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then
            if [ $i -lt 6 ]; then
                exact_value_of_frequency_=$(get_frequency_from_core "$i" "$frequency_level" "$PHONE_NAME_")
            elif [ $i -ge 6 ] && [ $i -lt 9 ]; then 
                exact_value_of_frequency_=$(get_frequency_from_core 6 "$frequency_level" "$PHONE_NAME_")
            elif [ $i -gt 8 ]; then 
                exact_value_of_frequency_=$(get_frequency_from_core 7 "$frequency_level" "$PHONE_NAME_")
            fi
          
        elif [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then
            if [ $i -lt 4 ]; then
                exact_value_of_frequency_=$(get_frequency_from_core "$i" "$frequency_level" "$PHONE_NAME_")
            elif [ $i -ge 4 ] && [ $i -lt 9 ]; then 
                # useless instruction
                exact_value_of_frequency_=0
            elif [ $i -gt 8 ]; then 
                exact_value_of_frequency_=$(get_frequency_from_core $[i-5] "$frequency_level" "$PHONE_NAME_") # we are in generic format, we do like we are on samsung format
                                                                                                              # and we substract 5 from the the high indice 9 becomes 4
            fi
        fi
        #echo "---+ Adding this frequency $exact_value_of_frequency_ to configuration "
        current_configuration_with_exact_frequencies+=($exact_value_of_frequency_)
        #echo "---+ current configuration : $(echo_array ${current_configuration_with_exact_frequencies[@]})"  # how to pass an array as parameter  
    done
    #echo " ---+ processing finished:"; echo_array ${current_configuration_with_exact_frequencies[@]}
    echo_csv_array ${current_configuration_with_exact_frequencies[@]}
}

function print_generic_format_from_configuration(){
    #for google pixel 0,0,0,0,0,0,  1,  0 -> [0,0,0,0,0,0,   1,0,0,   0,0,0,0]
    #for samsung galaxy 0,0,0,1, 0,1,0,0  -> [0,0,0,1,0,0,   0,0,0,   0,1,0,0]

    configuration_in_phone_format_=$1
    PHONE_NAME_=$2
    # getting exact values of frequencies
    generic_format=()
    IFS=',' read -r -a configurations_array <<< "$configuration_in_phone_format_"
    
    for  i in ${!configurations_array[@]};  
    do
        if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then
            #echo "---++ Frequency level of core $i is  ${configurations_array[$i]}"
            if [ $i -lt 6 ]; then
                frequency_level=${configurations_array[$i]}
                #echo " ---++ Adding this frequency $frequency_level to configuration "
                generic_format+=($frequency_level)
                #echo "current configuration : $(echo_array ${current_configuration_with_exact_frequencies[@]})"  # how to pass an array as parameter
            elif [ $i -eq 6 ]; then 
                frequency_level=${configurations_array[$i]}
                #echo " ---++ Adding this frequency $frequency_level to configuration "
                generic_format+=($frequency_level)
                generic_format+=("0")
                generic_format+=("0")
            elif [ $i -eq 7 ]; then 
                frequency_level=${configurations_array[$i]}
                #echo " ---++ Adding this frequency $frequency_level to configuration "
                generic_format+=($frequency_level)
                generic_format+=("0")
                generic_format+=("0")
                generic_format+=("0")
            fi
        elif [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then
               #echo "---++ Frequency level of core $i is  ${configurations_array[$i]}"
            if [ $i -lt 3 ]; then
                frequency_level=${configurations_array[$i]}
                #echo " ---++ Adding this frequency $frequency_level to configuration "
                generic_format+=($frequency_level)
                #echo "current configuration : $(echo_array ${current_configuration_with_exact_frequencies[@]})"  # how to pass an array as parameter
            elif [ $i -eq 3 ]; then 
                frequency_level=${configurations_array[$i]}
                #echo " ---++ Adding this frequency $frequency_level to configuration "
                generic_format+=($frequency_level)
                generic_format+=("0")
                generic_format+=("0")
                generic_format+=("0")
                generic_format+=("0")
                generic_format+=("0")
            elif [ $i -gt 3 ]; then 
                frequency_level=${configurations_array[$i]}
                #echo " ---++ Adding this frequency $frequency_level to configuration "
                generic_format+=($frequency_level)
            fi
        fi

    done
    #echo " ---++ processing finished:"; echo_array ${generic_format[@]}
    echo_csv_array ${generic_format[@]}
}


###### To test
function produce_suitable_input_file_from_human_readable_and_phone_format(){
    #this file takes as input a file like this 
    old_input_configurations_file_=$1
    new_input_configuration_file=$2
    PROJECT_TRASH_FOLDER_=$3
    PHONE_NAME_=$4
    mv $new_input_configuration_file ${PROJECT_TRASH_FOLDER_}/generated_configuration_file_deleted_on__$(date +'%d%h%y_%H_%M_%S')
    touch $new_input_configuration_file
    is_header=1
    while IFS=, read -r configurations  phone_format ; do
        if [ "$is_header" -ne "0" ]; then
            echo "--- Reading header $configurations and $exact_frequency_google_pixel"
            echo "--- Creating the file $new_input_configuration_file" 
            if [ "$PHONE_NAME_" = "google_pixel_4a_5g" ]; then #google_pixel_4a_5g or samsung_galaxy_s8
                echo "configurations,generic format,exact frequency,google pixel format,exact frequencies" > $new_input_configuration_file
            elif [ "$PHONE_NAME_" = "samsung_galaxy_s8" ]; then
                echo "configurations,generic format,exact frequency,samsung galaxy format,exact frequencies" > $new_input_configuration_file
            else
                  echo "configurations,generic format,exact frequency,phone format,exact frequencies" > $new_input_configuration_file
            fi
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


            echo "$configurations,$generic_format,$exact_frequency_generic,$phone_format, $exact_frequency_phone" >> $new_input_configuration_file

        fi
    done < $old_input_configurations_file_
}




:<<'END_COMMENT'

function produce_suitable_input_file_from_human_readable_and_phone_format(){
    #this file takes as input a file like this 
    old_input_configurations_file_=$1
    new_input_configuration_file=$2
    PROJECT_TRASH_FOLDER_=$3
    PHONE_NAME_=$4
    mv $new_input_configuration_file ${PROJECT_TRASH_FOLDER_}/generated_configuration_file_deleted_on__$(date +'%d%h%y_%H_%M_%S')
    touch $new_input_configuration_file
    is_header=1
    while IFS=, read -r configurations  google_pixel_format ; do
        if [ "$is_header" -ne "0" ]; then
            echo "--- Reading header $configurations and $google_pixel_format"
            echo "--- Creating the file $new_input_configuration_file" 
            echo "configurations,generic format,exact frequency,phone format,exact frequencies" > $new_input_configuration_file
            is_header=0
        else 
            #generic_format exact_frequency_generic  exact_frequency_google_pixel
            google_pixel_format=$(echo $google_pixel_format |   tr -d '\r' )
            echo " -- Cleaning phone format of configuration >$google_pixel_format<"
            configuration_in_google_pixel_format=${google_pixel_format:1:-1} # removing first and last hooks
            configuration_in_google_pixel_format=$(echo "$configuration_in_google_pixel_format" | sed 's/ //g' | sed 's/-/,/g' ) # removing spaces and replacing dashes by commas
            #echo " -- Getting generic format of configuration $configuration_in_google_pixel_format"
            generic_format=$(print_generic_format_from_configuration $configuration_in_google_pixel_format)
            echo " ----- Generic format: $generic_format"
            
            configuration_in_generic_format=${generic_format:1:-1} # removing first and last hooks
            configuration_in_generic_format=$(echo "$configuration_in_generic_format" | sed 's/ //g' | sed 's/-/,/g' )
            #echo " -- Getting generic format with exact frequencies of configuration $configuration_in_generic_format"
            exact_frequency_generic=$(print_generic_format_with_exact_frequencies_values $configuration_in_generic_format)
            echo " -- Generic format with exact frequencies:  $exact_frequency_generic"

            #echo " -- Getting exact frequencies of configuration $configuration_in_google_pixel_format"
            exact_frequency_google_pixel=$(echo_configuration_with_exact_value_of_frequencies $configuration_in_google_pixel_format)
            #exact_frequency_google_pixel=$(echo "$exact_frequency_google_pixel" | sed 's/,/- /g')
            #exact_frequency_google_pixel="[$exact_frequency_google_pixel]"
            echo " -- Exact frequencies: $exact_frequency_google_pixel"


            echo "$configurations,$generic_format,$exact_frequency_generic,$google_pixel_format, $exact_frequency_google_pixel" >> $new_input_configuration_file

        fi
    done < $old_input_configurations_file_
}
END_COMMENT





TESTING_PARSING_UTILS_SOURCING="--- parsing_utils.sh correctly loaded. "
