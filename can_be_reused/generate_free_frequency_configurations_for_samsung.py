



print("python call is find")
import random
from itertools import product


# Functions in this files help to generate from experiments realized, new configruations to test.
# For each configuration realized 
#    it we take for example the configuration C =  2202 3033
# we consider that the three sockets can be with userspace value of frequency (0) or with default value of frequency (1)
# So we have 2**2 possibilities to change or to not change the governor of sockets. 
#     If we decide to change the socket governor according to this doublet (1 0)
#      we will generate from C the new configuration  4404 3033
# Note that the level 4 of frequency, correspond to the default governor 
#           In the automatisation script, we plan to not modify the governor of the socket (or to set it with the default one)
#           In the model, we plan to factorize with another format where the governor bit of the socket can be 0 or 1 and the frequency level is 0 by default and the 
# so for all possible doublet (except  00), we generate possible configurations
# After doign it we reassure ourself to not have redondant configurations and to remove the one already tested




import itertools
import numpy as np
def generate_frequency_from_single_configuration(current_configuration):
    result = []
    all_governor_doublets = list(product(range(0, 2),range(0, 2)))
    print (" --- Generating one configuration from ", current_configuration)
    for governor_doublet in all_governor_doublets:
        if not np.array_equal([0, 0], governor_doublet):
            print (" --- Multiplication with doublet ", governor_doublet)
            current_generated_configuration = []
            for i in range(0, 4):
                frequency_level = 0
                if (current_configuration[i] != 0):
                    frequency_level = 4  if governor_doublet[0] == 1 else current_configuration[i] 
                current_generated_configuration.append(frequency_level) 

            for i in range(4, 8):
                frequency_level = 0
                if (current_configuration[i] != 0):
                    frequency_level = 4  if governor_doublet[0] == 1 else current_configuration[i] 
                current_generated_configuration.append(frequency_level) 

            print (" --- Result for the current doublet ", current_generated_configuration)
            result.append(current_generated_configuration)    
    return result 


import itertools
import numpy as np
def array_in_list_of_array(val, list_of_array):
    place = 0
    for curr in list_of_array:
        if (np.array_equal(curr, val)):
            return place
        place = place + 1

    return -1

def count_number_of_realized_configurations(configurations_realized):
    result = []
    for current_configuration in configurations_realized: 
        if array_in_list_of_array( current_configuration, result) == -1:
            result.append(current_configuration)
            print (" --- Configuration:   "+ repr(current_configuration) + " appended to result")
        else:
            print (" --- Configuration:   "+ repr(current_configuration) + " NOT appended to result, it is already present in config list")
    return len(result)

def generate_free_frequency_from_configurations(configurations_realized):
    print (" --- Generating configurations with default governor")
    result = []
    for current_configuration in configurations_realized:
        free_frequency_configurations = generate_frequency_from_single_configuration(current_configuration)
        for current_freq_free_config in free_frequency_configurations: 
            if array_in_list_of_array( current_freq_free_config, result) == -1:
                result.append(current_freq_free_config)
                print (" --- Configuration:   "+ repr(current_freq_free_config) + " appended to result")
            else:
                print (" --- Configuration:   "+ repr(current_freq_free_config) + " NOT appended to result, it is already present in config list")
    return result


def get_configurations_from_summary_file(summary_file_path):
    print (" --- Getting data from file ", summary_file_path)
    result = []
    summary_file = open(summary_file_path, 'r') 
    header=1
    while True:
        line = summary_file.readline()
        if not line:
            break
        if(header == 1):
            header=0
            continue
        print("--- Reading the line :", line)
        line_data = line.split(",")  
        current_configuration = line_data[3]
        current_configuration = (current_configuration[1:-1]).replace(" ", "").split("-")
        print ("arrays of value as string : ", current_configuration)
        X_line = [int(numeric_string) for numeric_string in current_configuration]
        print("resulted X configuration : ", X_line)
        result.append(X_line) 
    return result           
            



import os
def get_configurations_from_summary_folder( summary_folder_path ):
    total_result_list = []
    list_of_files = {}
    print (" --- Getting data from folder ", summary_folder_path)
    for (dirpath, dirnames, filenames) in os.walk(summary_folder_path):
        for filename in filenames:
            #if filename.endswith('.html'): 
            #list_of_files[filename] = os.sep.join([dirpath, filename])
            current_result_list = get_configurations_from_summary_file(os.sep.join([dirpath, filename]))
            total_result_list = total_result_list + current_result_list
    return total_result_list





def generate_configurations_and_substract_already_tested(number_of_combinaison = 40, 
    realized_experiments_summaries_folder= "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/summary_files_only",
    free_frequency_configuration_tested_summaries_folder= "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/summary_files_only",
    output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/generated_combinations.csv"):
    
    
    print (" --- Getting realised configurations (without level 4 frequency level) from folder: ", realized_experiments_summaries_folder)
    configurations_realized = get_configurations_from_summary_folder(realized_experiments_summaries_folder)
    
    print(" ___ size = ", count_number_of_realized_configurations(configurations_realized))
    
    print (" --- Generating configurations with level 4 frequency level from the above data ")
    generated_configurations = generate_free_frequency_from_configurations(configurations_realized)
    print(" --- Size of configurations generated : ", len(generated_configurations))
    
    print (" --- Getting already tested configurations with level 4 frequency level ")
    free_freq_configurations_already_tested =  get_configurations_from_summary_folder(free_frequency_configuration_tested_summaries_folder)


    print (" --- Substracting already tested configurations:")
    configurations_candidates =  []
    for current_freq_free_config in generated_configurations: 
        if array_in_list_of_array( current_freq_free_config, free_freq_configurations_already_tested) == -1:
            configurations_candidates.append(current_freq_free_config)
            print (" --- Configuration:   "+ repr(current_freq_free_config) + " appended to configuration candidates")
        else:
            print (" --- Configuration:   "+ repr(current_freq_free_config) + " NOT appended to configuration candidates, it has already been tested")
    
    print (" --- Selecting " +  str(number_of_combinaison) + " configurations and writing in file")
    list_of_retained_configurations = random.sample(configurations_candidates, number_of_combinaison)  

    with open(output_file_path,'w') as file:
        file.write("configurations,google pixel format\n")
        for retained_combination in list_of_retained_configurations:
            print ("--- Retained value to add in file: " + str(retained_combination))
            
            user_friendly = str(retained_combination)[1:-1].replace(" ", "")
            user_friendly = user_friendly[:7] + '-' + user_friendly[7+1:]
            user_friendly = str(user_friendly).replace(",", "")
            string_to_write=  user_friendly + "," + str(retained_combination).replace(",", "-")

            file.write(string_to_write)
            file.write('\n')
        print("--- Number of configurations generated = ", number_of_combinaison)
        print("--- Outpuf file = ", output_file_path)

    

number_of_combinaison = 40

generate_configurations_and_substract_already_tested (number_of_combinaison, 
    realized_experiments_summaries_folder= "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/SAMSUNG_RESULTS/summary_files_only_samsung_last_version", #summary_folder_google_p_for_free_freq_generation",
    free_frequency_configuration_tested_summaries_folder = "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/summary_files_only",
    output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/input_configurations_file.csv")

