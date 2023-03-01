



print("python call is find")
import random
from itertools import product


# Functions in this files help to generate from experiments realized, new configruations to test.
# For each configuration realized 
#    it we take for example the configuration C =  2202 1 3
# we consider that the three sockets can be with userspace value of frequency (0) or with default value of frequency (1)
# So we have 2**3 possibilities to change or to not change the governor of sockets. 
#     If we decide to change the socket governor according to this triplet (1 1 0)
#      we will generate from C the new configuration  4404 4 3
# Note that the level 4 of frequency, correspond to the default governor 
#           In the automatisation script, we plan to not modify the governor of the socket (or to set it with the default one)
#           In the model, we plan to factorize with another format where the governor bit of the socket can be 0 or 1 and the frequency level is 0 by default and the 
# so for all possible triplet (except  000), we generate possible configurations
# After doign it we reassure ourself to not have redondant configurations and to remove the one already tested




import itertools
import numpy as np
def generate_frequency_from_single_configuration(current_configuration):
    result = []
    all_governor_triplets = list(product(range(0, 2),range(0, 2) ,range(0, 2) ))
    print (" --- Generating one configuration from ", current_configuration)
    for governor_triplet in all_governor_triplets:
        if not np.array_equal([0, 0, 0], governor_triplet):
            print (" --- Multiplication with triplet ", governor_triplet)
            current_generated_configuration = []
            for i in range(0, 6):
                frequency_level = 0
                if (current_configuration[i] != 0):
                    frequency_level = 4  if governor_triplet[0] == 1 else current_configuration[i] 
                current_generated_configuration.append(frequency_level) 

            frequency_level = 0
            if (current_configuration[6] != 0):
                frequency_level = 4  if governor_triplet[1] == 1 else current_configuration[6] 
            current_generated_configuration.append(frequency_level) 
                    
            frequency_level = 0
            if (current_configuration[7] != 0):
                frequency_level = 4  if governor_triplet[2] == 1 else current_configuration[6] 
            current_generated_configuration.append(frequency_level) 
            print (" --- Result for the current triplet ", current_generated_configuration)
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
    all_governor_triplets = list(product(range(0, 2),range(0, 2) ,range(0, 2) ))
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
    
    # first case if we whant to tie to previous experiment to see difference with already tested configurations
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
            user_friendly=str(retained_combination)[1:-1].replace(" ", "")
            user_friendly = user_friendly[:11] + '-' + user_friendly[11+1:]
            user_friendly = user_friendly[:13] + '-' + user_friendly[13+1:]
            user_friendly = str(user_friendly).replace(",", "")
            string_to_write=  user_friendly + "," + str(retained_combination).replace(",", "-")

            file.write(string_to_write)
            file.write('\n')
        print("--- Number of configurations generated = ", number_of_combinaison)
        print("--- Outpuf file = ", output_file_path)

    

number_of_combinaison = 70

generate_configurations_and_substract_already_tested (number_of_combinaison, 
    realized_experiments_summaries_folder= "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/GOOGLE_PIXEL_RESULTS/summary_files_only_0.89", #summary_folder_google_p_for_free_freq_generation",
    free_frequency_configuration_tested_summaries_folder = "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/summary_files_only",
    output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/input_configurations_file.csv")

# NOTE about the number of configurations we should test to expect having correct balance without configurations with default governor and configirations with frequency modify. 
# The number of total possiblities (NT) is 
# 4 * 2^6 * 5 * 5 = 6400, because for little socket we have the 4 values : 0, 1, 2, 3 as frequency levels, 3 is for the default governor;
#                                for medium and big socket we have the level 0 - when not thread are scheduled on them, 1, 2, 3 and 4 as frequency levels
# The number of possibilities without the default governor activated is (N4_0)
# 3 * 2^6 * 4 * 4 (Note we juste reduced every where the number of frequency level every where it appears in formula, 4 becames 3 and 5 became 4)
# The number of possibilities with 4 at exactly one position and not anywhere (N4_1) else is , 
#         the number of possibilities with 4 at position 1 only  (1*2^6*4*4,  because we fix one value to 1 and considere only 4 levels of frequency)
#         plus the number of possibilities with 4 at position 2 only (3*2^6*1*4)
#        plus the number of possibilities with 4 at position 3 only (3*2^6*4*1)
#       (the intersection of the three last situations is null, so we remove nothing to them)
#         wich is 2560
# The number of possibilities with 4 at exactly two positions (N4_2) is 
#         the number of possibilities with 4 at position 1 and 2 only  (1*2^6*1*4,  because we fix tow values to 1 and considere only 4 levels of frequency)
#         plus the number of possibilities with 4 at position 2  and 3 only (3*2^6*1*1)
#        plus the number of possibilities with 4 at position 1 and  3 only (1*2^6*1*4)
#       (the intersection of the three last situations is null, so we remove nothing to them)
#         wich is 704
# The number of possibilities with 4 at exactly three positions (N4_3) is 
#          1*2^6*1*1
# The number of possibilities with 4 at least one position (N4__AL_1) is 
#     (N4_1) + (N4_2) + (N4_3) - intersection_of_the_three_situation_mentionned_in_this_formula = 3328 (the intersection_of_the_three_situation_mentionned_in_this_formula is null )
#
#  And finally we have  N4__AL_1 +  N4_0 =  NT
#                       3328  + 3072   = 6400 
#                    %N4__AL_1 = 3328/6400 = 0.52
#                    %N4_0   =  0.48
# so for the 649 configurations in situation N4_0
# correspond to 649 * (0.52/0.48) = 703.0 configurations tied to thems ---- > to test two weeks of 70 experiments 

