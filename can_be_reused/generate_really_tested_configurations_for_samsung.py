



print("python call is find")
import random
from itertools import product



# This file is another version of the file generate_configuration.py
# But in the functions in this file, we consider the fact that, 
# on some phones it is impossible to have cores on the same socket and with differents frequency level. 
# So the configurations generated, have the contrainst to have etheir 0 or one same not null frequency level for  cores 0 to 5
# and other frequency level on other sockets. 
# This file is dedicated for the samsung galaxy s8 phone.

# The number of possibilities are 
# 3  (becausethere are tree not null possible frequency levels for little socket)
#    2*2*2*2    (because there are for the little socket four positions with tow possible values - 0 or 1 each time for the core state)
#       *3  * (because there are tree not null possible frequency levels for Big socket) 
#    2*2*2*2    (because there are for Big socket four positions with tow possible values - 0 or 1 each time for the core state)

# the function convert_in_base will now convert et "4-uplet" of three decimals numbers to it  representation as a configuration
#  The first number of the 4-uplet  A1 * 3    will have three possible values from 0 to 3-1
#  The second number of the 4-uplet  B1 +   B2 * 2  + ... +  B5 * (2**3)  wil have 2*2*2*2 - 1 possible values
#  The third number of the 4-uplet  C1 
#  The fourth number of the 4-uplet  D1 +   D2 * 2  + ... +  D5 * (2**3)  wil have 2*2*2*2 - 1 possible values  

#         
# If the final human readable combination is c1, c2, c3, c4, c5, c6, c7, c8   
# [A human readable configuration is the one where each position reflect the frequency level of the core at that position]

# Knowing that if A1 is 0, the not nul frequency level present on first four sockets (where one of c1 to c4 is one) will be 1
#              if A1 is 1, the not nul frequency level present on first six sockets will be 2
#              if A1 is 2, the not nul frequency level present on first six  sockets will be 3

# We notice this notation the Base Y , The Y is for the lord Yéshoua
#       For exemple the initial human readable configuration    2, 2, 0, 2, 0, 0, 1, 1
#        will have the 4-uplet notation (1 in base 3) = 3, (1  1  0  1  in base 2) = ,  (0  in base 3) = , and (0, 0, 1,  1  in base 2) for the Big core =
#                                  1 because frequency level 2 is coded by 1 in the Base Y format 
#       For exemple the  human readable configuration   0, 3, 3, 3, 0, 0, 0, 2
#        will have the 4-uplet  notation (2 in base 3) =2 , (0  1  1  1 in base 2) = , (1  in base 3) =    (0  2 in base 4 ) = 
#                                  2 because frequency level 3 is coded by 2 in the Base Y format 
# NOTE we called the new base introduced the base Y notation, with is the concatenation of representation of the 4-uplet in all bases, 3 on one bit, 2 on six bits and 4 in two bits

# And we apply the same algorith exposed in file generate_configuration.py, to generate random configuration using each member of the 4-uplet. 
# SPECIAL CASES : the configuration where all little socket are down can have many possible representations in base Y , 
#               (It is the same case respectively when all Big sockets are down).
# This happens, because the value of the first bits (and respectively of the 5th bit) will no longer matter but it is not a great problem
# Because when generating configuration we plan to  remove them (as a special case) as if they  have been tested 
# theses numbers that we will remove are 
#         all possible number from 1 to 3-1, 0,  all possible number from 0 to 3-1, all possible number from 0 to 2*2*2*2 - 1, 
#         all possible number from 0 to 3-1, all possible number from 0 to 2*2*2*2 - 1,  all possible number from 1 to 3-1, 0
#  we only maintain the 4-uplet(  0, 0,  all possible number from 0 to 3-1, all possible number from 0 to 2*2*2*2 - 1, ), to represent configurations where the little socket is not active
#  we only maintain the 4-uplet( all possible number from 0 to 3-1, all possible number from 0 to 2*2*2*2 - 1,  0, 0), to represent configurations where the Big socket is not active

#  

def convert_in_base(decimal_value, base, length = 8):
    # convert a number in base 10 to its corresponding value in base Y"
    #For exemple the configuration   0, 3, 3, 3, 0, 0, 0, 2
    #will have the base notation  2  0  1  1  1  0  0  0  2
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



def convert_from_four_uplet_to_base_Y(four_uplet_of_decimal_value):
    # convert a four_uplet of decimal numbers from decimal base to  base 3, 2 and 3, 4 respectively "
    # return a list of concatenated arrays, each array is the representation of decimal number in the bases listed above
    # For exemple the four_uplet  (3, 4, 3, 2)
    # will have the base notation (( 3 in base 3 on one bits), (4 in base 2 on four bits )(3 in base 4 on tow bits) (2 in base 2 on four bits ))
    # this function will just return an array
    print (" --- converting " + repr(four_uplet_of_decimal_value) + "  to base Y  (  base 3 on 2 bits, 2 on 4 bits and base 3 on 2 bits, 2 on 4 bits)")

    result_1 = convert_in_base(four_uplet_of_decimal_value[0], 3, 1)
    result_2 = convert_in_base(four_uplet_of_decimal_value[1], 2, 4)
    result_3 = convert_in_base(four_uplet_of_decimal_value[2], 3, 1)
    result_4 = convert_in_base(four_uplet_of_decimal_value[3], 2, 4)
    result = result_1 + result_2 + result_3 + result_4

    print (" --- Result = ",  result)
    return result



def convert_from_base_Y_to_configuration_notation(array_in_base_Y):
    # convert a base Y notation on samsung S8 to the configuration notation 
    # this code will check the value of the first element of the array and apply the corresponding frequency level on next sixth element of the array given as parameter
    
    print (" --- Converting  base Y number " +  repr(array_in_base_Y) + " to configuration notation" )

    frequency_level = array_in_base_Y[0] + 1
    result = []
    
    for index in range(1, 5):
        if array_in_base_Y[index] == 1:
            result.append(frequency_level)
        else:
            result.append(0)


    frequency_level = array_in_base_Y[5] + 1    

    for index in range(6, 10):
        if array_in_base_Y[index] == 1:
            result.append(frequency_level)
        else:
            result.append(0)

        
    print (" --- Result = ",  result)
    return result



def convert_from_configuration_to_base_Y(configuration):
    # convert a configuration to base  Y (specific for samsung s8 with tow sockets, each socket having four cores)
    # return the result as a numpy array

    # getting the frequency level (the first not nul value in the six first numbers of configurations)
                                   # (other not nul values in the six first numbers of the configuration should be the same)
    print (" --- Converting " +  repr(configuration) + " in base Y array notation" )

    result = []

    print(" --- Processing the little socket")
    result.append(0)
    frequency_level = 0
    for index in range(0, 4):
        if configuration[index] != 0 :
            frequency_level = configuration[index]
            result.append(1)
        else: 
            result.append(0)
        
    if frequency_level == 0:
        result[0] = 0
    else :
        result[0] =  frequency_level - 1  
                          

    print(" --- Processing the big socket")
    result.append(0)
    frequency_level = 0
    for index in range(4, 8):
        if configuration[index] != 0 :
            frequency_level = configuration[index]
            result.append(1)
        else: 
            result.append(0)
        
    if frequency_level == 0:
        result[4] = 0
    else :
        result[4] =  frequency_level - 1  
                          


    
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

def convert_from_base_Y_to_four_uplet(array_in_base_Y):
    # convert a base Y notation ( base 3, 2, 3 and 2 respectively) to 4_uplet four_uplet of decimal numbers "
    # the input value is  a list of concatenated arrays, each array is the representation of decimal number in the bases listed above
  
    # it will have the base notation (( 3 in base 3 on one bits), (4 in base 2 on six bits )(3 in base 4 on tow bits))
    # this function will return  the four_uplet  (3, 4, 3)
    # this function will just return an array

    print (" --- Converting array " +  repr(array_in_base_Y) + " from base Y to four_uplet" )
    result_1 = convert_array_from_base([array_in_base_Y[0]], 3)
    result_2 = convert_array_from_base(array_in_base_Y[1:4], 2)
    result_3 = convert_array_from_base([array_in_base_Y[5]], 3)
    result_4 = convert_array_from_base(array_in_base_Y[6:9], 2)
    result  = [result_1, result_2, result_3, result_4 ]
    print (" --- Result  " +  repr(result) )

    return result



def convert_from_configuration_to_four_uplet(configuration):
    return convert_from_base_Y_to_four_uplet(convert_from_configuration_to_base_Y(configuration))
def convert_from_four_uplet_to_configuration(four_uplet):
    return convert_from_base_Y_to_configuration_notation(convert_from_four_uplet_to_base_Y(four_uplet))


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
        if len(line_data) >= 11:
            # when the cc_info varied during experiments we give another chance to the configuration to be tested, we don't consider it
            # we only consider configurations where cc_info_did not varied
            starting_cc_info = int(line_data[9])
            ending_cc_info =  int(line_data[10])
            if (ending_cc_info - starting_cc_info != 0):
                continue
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


def substract_already_tested_configurations (number_of_combinaison = 40, 
    configuration_tested_summaries_folder= "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/summary_files_only",
    output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/generated_combinations.csv"):
    # This function randomly generate configurations to test, it substract experiments already realized contained in file configuration_tested_summaries_folder
    configurations_already_tested = get_configurations_from_summary_folder(configuration_tested_summaries_folder)
    configurations_already_tested_as_four_uplet = []

    for configuration_as_array in configurations_already_tested:
        configurations_already_tested_as_four_uplet.append(convert_from_configuration_to_four_uplet(configuration_as_array))


    ## Now we substract the number in the list configurations_already_tested_as_int from all possible combinaisons
    
   
    special_cases_as_four_uplet_1 = list(product( range(1, 3), [0], range(0, 3), range(0, 2*2*2*2) )) # See Notation SPACIAL CASE in the introduction comment of the file
    special_cases_as_four_uplet_2 = list(product( range(0, 3), range(0, 2*2*2*2) , range(1, 3), [0] )) # See Notation SPACIAL CASE in the introduction comment of the file

    all_combinaisons_as_four_uplets =  list(product( range(0, 3), range(0, 2**4), range(0, 3), range(0, 2**4) ))

    
    configurations_candidates_as_four_uplets = [] # or list(set(all_combinaisons) - set(configurations_already_tested_as_int))
    print("--- Number of possible combinations ", len(all_combinaisons_as_four_uplets))
    for i in all_combinaisons_as_four_uplets:
        if ( array_in_list_of_array(i, configurations_already_tested_as_four_uplet) == -1):  # the value returned is not -1, meaning that the configuration is not tested 
            #print("In next experiments, we consider this value :" + str(i) ", configuration: ", repr(convert_in_base(i), len(possible_values) , 8))
            if  (array_in_list_of_array (i, special_cases_as_four_uplet_1) !=-1 ):  # in this configuration the little socket has all cores off 0, it can be [M, 0, N, L]
                                                                            # if it representant, the configuration [0,0, N, L] as four_uplet is not tested or considered as candidate we add it
                if ( array_in_list_of_array( [0, 0, i[2], i[3]], configurations_already_tested_as_four_uplet) == -1 \
                        and array_in_list_of_array( [0, 0, i[2], i[3]], configurations_candidates_as_four_uplets) == -1  ):
                    configurations_candidates_as_four_uplets.append([0, 0, i[2], i[3]])
                    print("--- Considering a new special case configuration: ", [0, 0, i[2], i[3]])
                    print("--- Adding the representant: ", [0, 0, i[2], i[3]])
                else:
                    print("--- Considering a new special case configuration: ", [0, 0, i[2], i[3]])
                    print("--- The representant already tested or added in candidates: ", [0, 0, i[2], i[3]])

            elif  (array_in_list_of_array (i, special_cases_as_four_uplet_2) !=-1 ):  # in this configuration the Big socket has all cores off 0, it can be [ N, L, M, 0]
                                                                            # if it representant, the configuration [ N, L, 0,0] as four_uplet is not tested or considered as candidate we add it
                if ( array_in_list_of_array( [i[0], i[1], 0, 0], configurations_already_tested_as_four_uplet) == -1 \
                        and array_in_list_of_array( [i[0], i[1], 0, 0], configurations_candidates_as_four_uplets) == -1  ):
                    configurations_candidates_as_four_uplets.append([i[0], i[1], 0, 0])
                    print("--- Considering a new special case configuration: ", [i[0], i[1], 0, 0])
                    print("--- Adding the representant: ", [i[0], i[1], 0, 0])
                else:
                    print("--- Considering a new special case configuration: ",[i[0], i[1], 0, 0])
                    print("--- The representant already tested or added in candidates: ",[i[0], i[1], 0, 0])

            else :
                print (" --- We are not in the presence of a special case, we add configuration :", i)
                configurations_candidates_as_four_uplets.append(i)



                
    print("--- Number of configuration candidates ", len(configurations_candidates_as_four_uplets))

    configurations_candidates_as_four_uplet_retained=random.sample(configurations_candidates_as_four_uplets, number_of_combinaison)
    list_of_retained_configurations=[]

    with open(output_file_path,'w') as file:
        file.write("configurations,samsung galaxy format\n")
        for decimal_four_uplet_retained in configurations_candidates_as_four_uplet_retained:
            retained_combination = convert_from_four_uplet_to_configuration(decimal_four_uplet_retained)
            list_of_retained_configurations.append(retained_combination)
            print ("--- Retained value to add in file: " + str(retained_combination) + ", indice : ", decimal_four_uplet_retained)
          
            user_friendly = str(retained_combination)[1:-1].replace(" ", "")
            user_friendly = user_friendly[:7] + '-' + user_friendly[7+1:]
            user_friendly = str(user_friendly).replace(",", "")
            string_to_write=  user_friendly + "," + str(retained_combination).replace(",", "-")

            file.write(string_to_write)
            file.write('\n')
    print("--- Number of configurations generated = ", number_of_combinaison)
    print("--- Outpuf file = ", output_file_path)


number_of_combinaison = 50

substract_already_tested_configurations (number_of_combinaison, 
    configuration_tested_summaries_folder= "/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/SAMSUNG_RESULTS/summary_files_only_samsung_last_version",
    output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/input_configurations_file.csv")
    #output_file_path="/mnt/c/Users/lavoi/opportunist_task_on_android/scripts_valuable_files/experiment_automatization/can_be_reused/input_configurations_file.csv")

# For the experiment I planned to run from 17h friday, to 9h monday,  (it means 65 hours = 3900 minutes)
#  If every experiment has 13 minits, we are suppose to run 4200/13 = 323 experiments 
#  So we choose 323 configurations in 4*4*4*4*4*4*4*4 = 65536   on google pixel, 

