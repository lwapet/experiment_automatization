



print("python call is find")
import random
from itertools import product


# In this file, we generate configurations to test strange cases.
# we reuse concepts already developped in other script.
# we reuse concepts like the base Y, four-uplets...
# these concepts have been also used in file generate_free_frequency_configurations_for_google_pixel.py



# NOTE: to integretate the situation where the governor of the socket is not touched, frequency level can take tbe value of 4
# in this case put this variable (consider_free_frequency) to 1 before continue
consider_free_frequency = 1
# To generate only configurations where there is at least one socket with default governor
only_with_frequency_free = True

if consider_free_frequency == 1: 
    max_frequency_level = 4
else: 
    max_frequency_level = 3
# TODO In some comment this value is 3 because we used 3 frequency levels at the beginning of the project (need to modify it later!!!)
# 

def convert_in_base(decimal_value, base, length = 8):
    # convert a number in base 10 to its corresponding value in base "base"
    # return the result as a numpy array
    print (" --- converting " + str(decimal_value) + " in base " + str(base))

    # first
    list_of_rest=[]
    if (decimal_value < base):
        list_of_rest.append(decimal_value)
        for index in range(len(list_of_rest), length):
            list_of_rest.append(0)
        print (" --- result ", list(reversed(list_of_rest)))
        return  list(reversed(list_of_rest))
    
    
    
    last_result = decimal_value
    while last_result >= base:    
        print (" --- appending " + str(int(last_result) % int(base)) + " to result")
        list_of_rest.append(int(last_result) % int(base))
        last_result = last_result/base
    print (" --- appending " + str(int(last_result)) + " to result")
    list_of_rest.append(int(last_result))

    for index in range(len(list_of_rest), length):
        list_of_rest.append(0)

    print (" --- result ", list(reversed(list_of_rest)))

    return list(reversed(list_of_rest))



def convert_from_triplet_to_base_Y(triplet_of_decimal_value):
    # convert a triplet of decimal numbers from decimal base to  base 3, 2 and 4 respectively "
    # return a list of concatenated arrays, each array is the representation of decimal number in the bases listed above
    # For exemple the triplet  (3, 4, 3)
    #  the input array  will have the base notation (( 3 in base max_frequency_level on one bits), (4 in base 2 on six bits )(3 in base max_frequency_level+1 on tow bits))
    # this function will just return an array
    print (" --- converting " + repr(triplet_of_decimal_value) + "  to base Y  (  base 3 on 2 bits, 2 on 6 bits and 4 on 2 bits)")

    result_1 = convert_in_base(triplet_of_decimal_value[0], max_frequency_level, 1)
    result_2 = convert_in_base(triplet_of_decimal_value[1], 2, 6)
    result_3 = convert_in_base(triplet_of_decimal_value[2], max_frequency_level+1, 2)
    result = result_1 + result_2 + result_3

    print (" --- Result = ",  result)
    return result



def convert_from_base_Y_to_configuration_notation(array_in_base_Y):
    # convert a base Y notation to the configuration notation 
    # this code will check the value of the first element of the array and apply the corresponding frequency level on next sixth element of the array given as parameter
    
    print (" --- Converting  base Y number " +  repr(array_in_base_Y) + " to configuration notation" )

    frequency_level = array_in_base_Y[0] + 1
    result = []
    
    for index in range(1, 7):
        if array_in_base_Y[index] == 1:
            result.append(frequency_level)
        else:
            result.append(0)
    for index in range(7, len(array_in_base_Y)):
        result.append(array_in_base_Y[index])
        
    print (" --- Result = ",  result)
    return result



def convert_from_configuration_to_base_Y(configuration):
    # convert a configuration to base  Y 
    # return the result as a numpy array

    # getting the frequency level (the first not nul value in the six first numbers of configurations)
                                   # (other not nul values in the six first numbers of the configuration should be the same)
    print (" --- Converting " +  repr(configuration) + " in base Y array notation" )

    result = []
    result.append(0)
    frequency_level = 0
    for index in range(0, 6):
        if configuration[index] != 0 :
            frequency_level = configuration[index]
            result.append(1)
        else: 
            result.append(0)
        
    if frequency_level == 0:
        result[0] = 0
    else :
        result[0] =  frequency_level - 1  
                          
    for index in range(6, len(configuration)):
        result.append(configuration[index])
    print (" --- Result = ",  result)
    return result


def convert_array_from_base(array_of_values, base):
    # convert a number  in base "base" to its corresponding value  in base 10 
    # return the result as a numpy array 
    print (" --- Converting array " +  repr(array_of_values) + " from base " + str(base) + " to decimal" )
    result = 0
    for index in range(0, len(array_of_values)):
        j = len(array_of_values) - 1   - index
        result = result +  array_of_values[j] * ( base ** index )

    print (" --- result ", result)

    return result

def convert_from_base_Y_to_triplet(array_in_base_Y):
    # convert a base Y notation ( base 3, 2 and 4 respectively) to triplet triplet of decimal numbers "
    # the input value is  a list of concatenated arrays, each array is the representation of decimal number in the bases listed above
  
    # it will have the base notation (( 3 in base 3 on one bits), (4 in base 2 on six bits )(3 in base 4 on tow bits))
    # will return  the triplet  (3, 4, 3)
    # this function will just return an array

    print (" --- Converting array " +  repr(array_in_base_Y) + " from base Y to triplet" )
    result_1 = convert_array_from_base([array_in_base_Y[0]], max_frequency_level)
    result_2 = convert_array_from_base(array_in_base_Y[1:6], 2)
    result_3 = convert_array_from_base(array_in_base_Y[7:8], max_frequency_level+1)
    result  = [result_1, result_2, result_3 ]
    print (" --- Result  " +  repr(result) )

    return result



def convert_from_configuration_to_tripet(configuration):
    return convert_from_base_Y_to_triplet(convert_from_configuration_to_base_Y(configuration))
def convert_from_triplet_to_configuration(triplet):
    return convert_from_base_Y_to_configuration_notation(convert_from_triplet_to_base_Y(triplet))


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


import itertools
import numpy as np
def array_in_list_of_array(val, list_of_array):
    place = 0
    for curr in list_of_array:
        if (np.array_equal(curr, val)):
            return place
        place = place + 1

    return -1


def four_is_in_configuration(i):
    configuration_as_array = convert_from_triplet_to_configuration(i)
    for i in configuration_as_array:
        if i == 4: 
            return True
    return False


def generate_configurations_for_strange_cases (
    output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/generated_combinations.csv", experiment_step = "big_and_medium_cores_off"):
    
    # This function randomly generate configurations to test, 
    # configurations like (1,1,0,0,0,0,  V,  V)
    #                     (1,0,1,0,0,0,  V,  V)
    #                     (1,0,0,1,0,0,  V,  V)
    #                          ... and so on : 1 on the first core, 1 on other core,  0 on other sockets
    #                          ... and the same think with 2, 3 , and 4 dispite of one. (so that the frequency level changes)  
    #                          ... and each configuration is repeated 3 times for correctness  
    # Note: V depends on the experiments step
    constant_mask = 2**5
    #byte_masks = []
    little_socket_possible_states = []
    for i in range(0,5):
        #byte_mask.appand(2**i)
        little_socket_possible_states.append(constant_mask | 2**i)
        print ("--- Configuration added :  ", convert_in_base(constant_mask | 2*i, 2, 6))

    if experiment_step == "big_and_medium_cores_off":
        big_medium_socket_possible_states =  range(0, 1)
    elif experiment_step == "big_and_medium_cores_at_mid_freq":
        big_medium_socket_possible_states =  range(12, 13)  # (2, 2) in base 5

    all_combinaisons_to_test_as_triplet = list(product( range(0, max_frequency_level), little_socket_possible_states , big_medium_socket_possible_states))
    all_combinaisons_to_test_as_triplets = list(itertools.chain.from_iterable(itertools.repeat(x, 3) for x in all_combinaisons_to_test_as_triplet))
        
    number_of_combinaison = 0
   
    list_of_retained_configurations=[]

    with open(output_file_path,'w') as file:
        file.write("configurations,google pixel format\n")
        for decimal_triplet_retained in all_combinaisons_to_test_as_triplets:
            retained_combination = convert_from_triplet_to_configuration(decimal_triplet_retained)
            list_of_retained_configurations.append(retained_combination)
            print ("--- Retained value to add in file: " + str(retained_combination) + ", indice : ", decimal_triplet_retained)
            user_friendly=str(retained_combination)[1:-1].replace(" ", "")
            user_friendly = user_friendly[:11] + '-' + user_friendly[11+1:]
            user_friendly = user_friendly[:13] + '-' + user_friendly[13+1:]
            user_friendly = str(user_friendly).replace(",", "")
            string_to_write=  user_friendly + "," + str(retained_combination).replace(",", "-")

            file.write(string_to_write)
            file.write('\n')
            number_of_combinaison =  number_of_combinaison + 1
    print("--- Number of configurations generated = ", number_of_combinaison)
    print("--- Outpuf file = ", output_file_path)



#experiment_step = "big_and_medium_cores_off"
experiment_step = "big_and_medium_cores_at_mid_freq"

generate_configurations_for_strange_cases (
    output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/input_configurations_file.csv", experiment_step= "big_and_medium_cores_at_mid_freq")

