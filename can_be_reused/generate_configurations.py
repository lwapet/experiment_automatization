



print("python call is find")
import random
from itertools import product

def compute_all_combination_of_threads_naive_approach (number_of_combinaison = 10, number_of_cores = 6, possible_values = [0,1,2,3],
 file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/generated_combinations.csv"):
    # This function compute all possible combinaison of "number_of_cores" -uples
    # Knowing that each value of the -uple can have one of the values contained in possible_values.
    # 
    # The strategy is to virually  generate all possibles value in an array 
    # And from this array, randomly selecting only "number_of_combinaison" indices between 0 and length(possible_values)^number_of_cores - 1
    # 
    print("--- Computing combinations with naive approach")
    list_of_permutations=list(product(range(0, len(possible_values)), repeat=number_of_cores))
    list_of_retained_indices=random.sample(range(0, len(possible_values) ** number_of_cores), number_of_combinaison)
    list_of_retained_values=[]
    with open(file_path,'w') as file:
        file.write("configurations,google pixel format\n")
        for indice_retained in list_of_retained_indices:
            retained_combination=list_of_permutations[indice_retained]
            list_of_retained_values.append(retained_combination)
            print ("--- Retained value added to file: " + repr(retained_combination) + ", indice : " + str(indice_retained))
            user_friendly=str(retained_combination)[1:-1].replace(" ", "")
            user_friendly = user_friendly[:11] + '-' + user_friendly[11+1:]
            user_friendly = user_friendly[:13] + '-' + user_friendly[13+1:]
            user_friendly = str(user_friendly).replace(",", "")
            string_to_write=  user_friendly + "," + str(retained_combination).replace(",", "-")
            file.write(string_to_write)
            file.write('\n')
    return list_of_retained_values


def convert_in_base(decimal_value, base, length = 8):
    # convert a number in base 10 to its corresponding value in base "base"
    # return the result as a numpy array
    #print (" --- converting " + str(decimal_value) + " in base " + str(base))
    list_of_rest=[]
    if (decimal_value < base):
        list_of_rest.append(decimal_value)
        return list_of_rest
    
    
    last_result = decimal_value
    while last_result >= base:    
        #print (" --- appending " + str(int(last_result) % int(base)) + " to result")
        list_of_rest.append(int(last_result) % int(base))
        last_result = last_result/base
    #print (" --- appending " + str(int(last_result)) + " to result")
    list_of_rest.append(int(last_result))

    for index in range(len(list_of_rest), length):
        list_of_rest.append(0)

    #print (" --- result ", list(reversed(list_of_rest)))

    return list(reversed(list_of_rest))


def convert_array_from_base(array_of_values, base):
    # convert a number  in base "base" to its corresponding value  in base 10 
    # return the result as a numpy array
    result = 0
    for index in range(0, len(array_of_values)):
        j = len(array_of_values) - 1   - index
        result = result +  array_of_values[j] * ( base ** index )

    #print (" --- result ", result)

    return int(result)

def compute_all_combination_of_threads_base_notation_approach (number_of_combinaison = 10, number_of_cores = 6, possible_values = [0,1,2,3],
 file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/generated_combinations.csv"):

    ## The previous approach seems naive, because,
    # each combinaison can be seen as a representation 
    # of a certain decimal number
    # in the base size(possible_value)
    #  Knowing that this number has "number_of_core" caracters
    #   
    # So first step is to select number_of_combinaison values in the range going from 0  to (length(possible_values)^number_of_cores - 1)
    # and then convert those numbers in base "possible_values"
    # and finally retain the lis of the combinaitions associated to theses values.
    #  

    print("--- Computing combinations with the approach based of decimal conversion")
    list_of_retained_indices=random.sample(range(0, len(possible_values) ** number_of_cores), number_of_combinaison)
    list_of_retained_values=[]

    with open(file_path,'w') as file:
        file.write("configurations,google pixel format\n")
        for decimal_value_retained in list_of_retained_indices:
            retained_combination = convert_in_base(decimal_value_retained, len(possible_values), number_of_cores)
            list_of_retained_values.append(retained_combination)
            print ("--- Retained value added to file: " + str(retained_combination) + ", indice : " + str(decimal_value_retained))
            user_friendly=str(retained_combination)[1:-1].replace(" ", "")
            user_friendly = user_friendly[:11] + '-' + user_friendly[11+1:]
            user_friendly = user_friendly[:13] + '-' + user_friendly[13+1:]
            user_friendly = str(user_friendly).replace(",", "")
            string_to_write=  user_friendly + "," + str(retained_combination).replace(",", "-")


            file.write(string_to_write)
            file.write('\n')


def substract_already_tested_configuration (configurations_input_file, configuration_to_subtract, configuration_output_file):
    ## This function substract some configurations from a list of configurations.
    #  The configurations passed as input are the one generated by function above
    # The configuration to substract are the one already tested 
    # They are readed by these function  in a summary file generated by the automatization script 
    # As a result we should have a list of configuration with the same format as the list passed as input. 
    
    print("--- Raeding the configuration to subtract file ")
    list_of_configuration_to_substract=[]
    file_to_subtract = open(configuration_to_subtract, 'r')
    header=1
    while True:
        line = file_to_subtract.readline()
        if not line:
            break
        datas_in_line = line.split(",")
        configuration_as_string=datas_in_line[0]
        if(header == 0):
            print("--- Reading next configuration to substract", configuration_as_string)
            list_of_configuration_to_substract.append(configuration_as_string)
        if (header == 1):
            header=0
      
    file_to_subtract.close()

    print("--- Writing the configuration output file ")   
    with open(configuration_output_file,'w') as file:
        file.write("configurations,google pixel format\n")
        input_file = open(configurations_input_file, 'r') 
        header=1
        while True:
            line = input_file.readline()
            if not line:
                break
            if(header == 1):
                header=0
                continue
            
            datas_in_line = line.split(",")
            current_configuration_as_string=datas_in_line[0]
            print ("--- Testing this configuration ", current_configuration_as_string)
            if (current_configuration_as_string in list_of_configuration_to_substract ):
                print("--- We don't add this configuration ",current_configuration_as_string)
            else:
                print ("--- We add this configuration")
                file.write(line)         
        input_file.close()


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
        X_line = [float(numeric_string) for numeric_string in current_configuration]
        print("resulted X configuration : ", X_line)
        result.append(X_line) 
    return result           
            

def substract_already_tested_configurations (number_of_combinaison = 40, number_of_cores = 8, possible_values = [0,1,2,3],
    configuration_tested_summaries_folder= "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/summary_files_only",
    output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/generated_combinations.csv"):
    # This function randomly generate configurations to test, it substract experiments already realized contained in file configuration_tested_summaries_folder
    configurations_already_tested = get_configurations_from_summary_folder(configuration_tested_summaries_folder)
    configurations_already_tested_as_int = []
    base = len(possible_values)
    for configuration_as_array in configurations_already_tested:
        configurations_already_tested_as_int.append(convert_array_from_base(configuration_as_array,base))
    ## Now we substract the number in the list configurations_already_tested_as_int from all possible combinaisons
    all_combinaisons = range(0, len(possible_values) ** number_of_cores)
    configurations_candidates = [] # or list(set(all_combinaisons) - set(configurations_already_tested_as_int))
    print("--- Number of possible combinations ", len(all_combinaisons))
    for i in all_combinaisons:
        if (i not in configurations_already_tested_as_int):
            #print("In next experiments, we consider this value :" + str(i) ", configuration: ", repr(convert_in_base(i), len(possible_values) , 8))
            configurations_candidates.append(i)

    configurations_candidates = list(set(all_combinaisons) - set(configurations_already_tested_as_int))
    print("--- Number of configuration candidates ", len(configurations_candidates))

    list_of_retained_indices=random.sample(configurations_candidates, number_of_combinaison)
    list_of_retained_values=[]

    with open(output_file_path,'w') as file:
        file.write("configurations,google pixel format\n")
        for decimal_value_retained in list_of_retained_indices:
            retained_combination = convert_in_base(decimal_value_retained, len(possible_values), number_of_cores)
            list_of_retained_values.append(retained_combination)
            #print ("--- Retained value added to file: " + str(retained_combination) + ", indice : " + str(decimal_value_retained))
            user_friendly=str(retained_combination)[1:-1].replace(" ", "")
            user_friendly = user_friendly[:11] + '-' + user_friendly[11+1:]
            user_friendly = user_friendly[:13] + '-' + user_friendly[13+1:]
            user_friendly = str(user_friendly).replace(",", "")
            string_to_write=  user_friendly + "," + str(retained_combination).replace(",", "-")

            file.write(string_to_write)
            file.write('\n')
    print("--- Number of configurations generated = ", number_of_combinaison)
    print("--- Outpuf file = ", output_file_path)


number_of_combinaison = 40
number_of_cores = 8

substract_already_tested_configurations (number_of_combinaison, number_of_cores, possible_values = [0,1,2,3],
    configuration_tested_summaries_folder= "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/summary_files_only",
    output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/input_configurations_file.csv")
# For the experiment I planned to run from 17h friday, to 9h monday,  (it means 65 hours = 3900 minutes)
#  If every experiment has 13 minits, we are suppose to run 4200/13 = 323 experiments 
#  So we choose 323 configurations in 4*4*4*4*4*4*4*4 = 65536   on google pixel, 

