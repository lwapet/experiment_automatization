#!/usr/bin/bash

echo "test "
# Declare a string array
arr_Var=("AC" "TV" "Mobile" "Fridge" "Oven" "Blender")

# Add new element at the end of the array
arr_Var+=("Dish Washer")

# Iterate the loop to read and print each array element
for value in "${arr_Var[@]}"
do
     echo $value
done

function echo_array(){
    arrVar=("$@")
    result="("
    for value in "${arrVar[@]}";do
        result=${result}$value","
    done
    result=${result::-1}")"
    echo $result
}
current_configuration_with_exact_frequencies=("0") 
current_configuration_with_exact_frequencies+=("22")

echo_array ${current_configuration_with_exact_frequencies[@]}