
import sys as sys

#parameters : 
    # sys.argv[1] the function code to execute during experiements:
      # 1 is for reduce_samples_datas_in_one_file
    # sys.argv[from 2 to n] Eventually, argument related to the function to execute
      ## for function code 1, ie reduce_samples_datas_in_one_file
      # sys.argv[2] = mesurement_file name
      # sys.argv[3] = new_mesurement_file name

    # sys.argv[1] the function code to execute during experiements:
      # 2 is for 
    # sys.argv[from 2 to n] Eventually, argument related to the function to execute
      ## for function code 1, ie reduce_samples_datas_in_one_file
      # sys.argv[2] = mesurement_file name
      # sys.argv[3] = new_mesurement_file name


#print ("--- Inside the reduce_moonson_sample, arg function: ", sys.argv[1])
#print("--- Python call is find")
def reduce_samples_datas_in_one_file(mesurement_file_path, new_mesurement_file_path):
    with open(new_mesurement_file_path,'w') as output_file:
        string_to_write_in_file = "Time(ms),USB Current(mA),USB Voltage(V),"
        print(" --- Actual line to write in file:", string_to_write_in_file)
        output_file.write(str(string_to_write_in_file))
        print (" --- Getting data from file ", mesurement_file_path)
        counter=0
        mesurement_file = open(mesurement_file_path, 'r') 
        part_to_drop=2
        first_line=1
        timeStampToWrite=0
        CurrentToWrite=0
        VoltageToWrite=0
        while True:
            line = mesurement_file.readline()
            if not line:
                break
            if(part_to_drop != 0):  # There where an error in the automatization script, it added the calibration result to the overall one
                line_data_ = line.split(",")
                line_data_ = line_data_[:len(line_data_)-1]
                string_=line_data_[0]
                if (string_=="Time(ms)"):
                    part_to_drop = part_to_drop-1 
                continue
            if(first_line==1):
                first_line=0
                print("--- Reading the line :", line)
                line_data_ = line.split(",")
                line_data_ = line_data_[:len(line_data_)-1]
                print("--- converting :", repr(line_data_))
                line_data = [float(numeric_string) for numeric_string in line_data_]
                timeStampToWrite = line_data[0]
                continue
            #print("--- Reading the line :", line)
            line_data_ = line.split(",") 
            line_data_ = line_data_[:len(line_data_)-1]  # to remove the \n at the end
            line_data = [float(numeric_string) for numeric_string in line_data_]
            timeStamp = line_data[0]
            Current = line_data[1]
            Voltage = line_data[2] 
            CurrentToWrite = CurrentToWrite + Current
            VoltageToWrite = VoltageToWrite + Voltage
            if (counter % 125 == 0):
                timeStampToWrite = (timeStampToWrite +  timeStamp)/2
                CurrentToWrite = CurrentToWrite / 125
                VoltageToWrite = VoltageToWrite / 125
                #print(" Mesurement at time " + repr(timeStamp) + ", USB Current: " + repr(Current) + " mA, USBVoltage" +  repr(Voltage) + " V")
                #print(" Mesurement to write in file at time " + repr(timeStampToWrite) + ", USB Current: " + repr(CurrentToWrite) + " mA, USBVoltage" +  repr(VoltageToWrite) + " V")
                output_file.write("\n" + repr(timeStampToWrite) + "," + repr(CurrentToWrite) + "," + repr(VoltageToWrite) + ",")
                timeStampToWrite = timeStamp
                CurrentToWrite=0
                VoltageToWrite=0
            counter = counter + 1
        output_file.write('\n')

        print(str(counter) + " samples have been written in file ", new_mesurement_file_path)
  





def recompute_powermeter_summary_from_mWs_to_mAh(mesurement_file_path, number_of_samples_per_second_):
        result = ""      
        number_of_samples_per_second = int(number_of_samples_per_second_)
        number_of_sample_per_mi_second = number_of_samples_per_second / 2


        tag = "--- Recomputing powermeter_summary_from_mWs_to_mAh"

        #print (" --- Getting data from file ", mesurement_file_path)
        counter=0
        
        part_to_drop=2
        first_line=1



        energy_consumption_mW_seconds = 0
        energy_consumption_mA_seconds = 0
        energy_consumption_w_h = 0
        energy_consumption_mA_h = 0
        number_of_samples_used_to_compute_energy = 0
        mesurement_file = open(mesurement_file_path, 'r') 
        while True:
            line = mesurement_file.readline()
            if not line:
                break
            if(part_to_drop != 0):  # There where an error in the automatization script, it added the calibration result to the overall one
                #print("--- Dropping datas :", line)
                line_data_ = line.split(",")
                line_data_ = line_data_[:len(line_data_)-1]
                string_=line_data_[0]
                if (string_=="Time(ms)"):
                    part_to_drop = part_to_drop-1 
                continue
            if(first_line==1):
                first_line=0
                #print("--- Reading the line :", line)
                line_data_ = line.split(",")
                line_data_ = line_data_[:len(line_data_)-1]
                #print("--- converting :", repr(line_data_))
                line_data = [float(numeric_string) for numeric_string in line_data_]
                firstTimeStamp = line_data[0]
                #print("--- First time :", firstTimeStamp)
                continue
            #print("--- Reading the line :", line)
            line_data_ = line.split(",") 
            line_data_ = line_data_[:len(line_data_)-1]  # to remove the \n at the end
            line_data = [float(numeric_string) for numeric_string in line_data_]
            timeStamp = line_data[0]
            Current = line_data[1]
            Voltage = line_data[2] 
            #print("--- Reading the line :"  + str(counter) + ",  Current = " + str(Current) + " Voltage = " + str(Voltage))
            if (counter % number_of_samples_per_second == number_of_sample_per_mi_second): # because we integrete the energy at unit of time ie second per second, not at every sampling (200us), 
                
                energy_consumption_mW_seconds = energy_consumption_mW_seconds + Current * Voltage 
                energy_consumption_mA_seconds = energy_consumption_mA_seconds + Current
                number_of_samples_used_to_compute_energy = number_of_samples_used_to_compute_energy + 1
                #print( tag + " Aggregating energy mAs " +  str(energy_consumption_mA_seconds) + ", Number of aggregation " + str(number_of_samples_used_to_compute_energy))
            counter = counter+1
        
        #print( tag + " --- We computed the energy on " + str(number_of_samples_used_to_compute_energy) + " samples")
        energy_consumption_mW_h = energy_consumption_mW_seconds / 3600
        energy_consumption_mA_h = energy_consumption_mA_seconds / 3600

        number_of_samples = counter
        exact_duration = timeStamp - firstTimeStamp

        average_current=0
        average_voltage=0

        #print("--- Getting average current and voltage")
        
        mesurement_file = open(mesurement_file_path, 'r') 
        counter=0
        part_to_drop=2
        first_line=1
        while True:
            line = mesurement_file.readline()
            if not line:
                break
            if(part_to_drop != 0):  # There where an error in the automatization script, it added the calibration result to the overall one
                #("--- Dropping datas :", line)
                line_data_ = line.split(",")
                line_data_ = line_data_[:len(line_data_)-1]
                string_=line_data_[0]
                if (string_=="Time(ms)"):
                    part_to_drop = part_to_drop-1 
                continue
            if(first_line==1):
                first_line=0
                #print("--- Reading the line :", line)
                line_data_ = line.split(",")
                line_data_ = line_data_[:len(line_data_)-1]
                #print("--- converting :", repr(line_data_))
                line_data = [float(numeric_string) for numeric_string in line_data_]
                firstTimeStamp = line_data[0]
                continue
           
            line_data_ = line.split(",") 
            line_data_ = line_data_[:len(line_data_)-1]  # to remove the \n at the end
            line_data = [float(numeric_string) for numeric_string in line_data_]
            Current = line_data[1]
            Voltage = line_data[2] 
            average_current = average_current +  Current
            average_voltage = average_voltage + Voltage
            counter = counter + 1
            if (counter ==  number_of_samples/2):
                instantanious_current = Current
            
        average_current = average_current/number_of_samples
        average_voltage = average_voltage/number_of_samples
        average_power = average_current * average_voltage

        #print(tag + " average_power = ", average_power)
        #print(tag + " average_voltage = ", str(average_voltage))
        average_voltage_ = str(average_voltage)

        result = ("time (s): " + repr(exact_duration) + 
                "\nIns Current (mA):" + repr(instantanious_current) + ## for floor division, just to have an idea of the current during experiment, I don't know if it the same explanation in powermeter summary window.
                "\nSamples: " + repr(number_of_samples) +
                "\nConsumed Energy (mAs): " + repr(energy_consumption_mA_seconds) +  
                "\nConsumed Energy (mAh): " + repr(energy_consumption_mA_h) +  
                "\nConsumed Energy (mWs): " + repr(energy_consumption_mW_seconds) +  
                "\nConsumed Energy (mWh): " + repr(energy_consumption_mW_h) +       
                "\nAvg power (mW): " + repr(average_power) + 
                "\nAvg Current (mA): " + repr(average_current) +  
                "\nAvg Voltage (V): " + repr(average_voltage) +    
                "\nExp Batt Life (hrs for 1000mAh battery): NOT COMPUTED " ) 
        #print (tag + "Summary Result = "+ result)
        return result
                    

            

if (sys.argv[1] == "1"):
    print (" --- Reducing monsoon sample, mesurement file = " + sys.argv[2] )
    print (" --- Reducing monsoon sample, output mesurement file = " + sys.argv[3] )
    reduce_samples_datas_in_one_file(sys.argv[2], sys.argv[3])
elif (sys.argv[1] == "2"):
    #print (" --- Recomputing powermeter summary, experiment file = " + sys.argv[2] )
    #print (" --- Recomputing powermeter summary, number of samples per second  = " + sys.argv[3] )
    print(recompute_powermeter_summary_from_mWs_to_mAh(sys.argv[2], sys.argv[3]))





"""

# It could be good to used this function before reducing the data with the first one
# So use it in the original mesurement file. 
function recompute_powermeter_summary_from_mWs_to_mAh(){
    #  recompute powermeter summary file
   

        mesurement_file=$1 
        number_of_samples_per_second_=$2 
        
        number_of_samples_per_mi_second=$((number_of_sample_per_second / 2))

      
        result=""
        counter=0
        is_first_data=1
        
        energy_consumption_mW_seconds=0
        energy_consumption_mA_seconds=0
        energy_consumption_w_h=0
        energy_consumption_mA_h=0
        number_of_measurements=$(wc -l $mesurement_file)
        number_of_measurements=$((number_of_measurements - 1))

        while IFS=, read -r  timeStamp USB_Current USB_voltage  ; do
            if [ "$is_header" -ne "0" ]; then
                echo "--- Reading header $sample_time, $USB_Current and  $USB_voltage "
                is_header=0
            else
                if [ "$is_first_data" -ne "0" ]; then
                    is_first_data=0
                    firstTimeStamp=$timeStamp
                fi
                USB_voltage=$(echo $USB_voltage |   tr -d '\r' )
                if [ "$((counter % number_of_samples_per_second_))" -eq $number_of_samples_per_mi_second ]; then
                    USB_voltage=$(echo $USB_voltage |   tr -d '\r' )                          
                    energy_consumption_mW_seconds=$((energy_consumption_mW_seconds + USB_Current * USB_voltage ))
                    energy_consumption_mA_seconds=$((energy_consumption_mA_seconds + Current))
                    number_of_samples_used_to_compute_energy=$((number_of_samples_used_to_compute_energy + 1))
                    echo " Cumulated energy for now: $energy_consumption_mW_seconds "
                fi  
                if [ "$counter" -eq "$((number_of_measurements / 2))" ]; then
                    instantanious_current=$USB_Current  ## for floor division, just to have an idea of the current during experiment, I don't know if it the same explanation in powermeter summary window.
                fi  
                echo " We computed the energy on $number_of_samples_used_to_compute_energy samples"
                energy_consumption_mW_h=$((energy_consumption_mW_seconds / 3600))
                energy_consumption_mA_h=$((energy_consumption_mA_seconds / 3600))  
                counter=$((counter + 1))
            fi      
        done < $mesurement_file


        average_current=0
        average_voltage=0
        while IFS=, read -r  timeStamp USB_Current USB_voltage  ; do
            if [ "$is_header" -ne "0" ]; then
                echo "--- Reading header $sample_time, $USB_Current and  $USB_voltage "
                is_header=0
            else
                USB_voltage=$(echo $USB_voltage |   tr -d '\r' )
                average_current=$((average_current + USB_Current))
                average_voltage=$((average_voltage + USB_voltage)) 
            fi      
        done < $mesurement_file

        
        average_current=$((average_current/number_of_samples))
        average_voltage=$((average_voltage/number_of_samples))
        average_power=$((average_current*average_voltage))
        echo "average_power = $average_power"
    
        exact_duration=$((timeStamp - firstTimeStamp))
        echo " Expermiment duration : $exact_duration"
        number_of_samples=$counter
        echo "Number of samples =  $number_of_samples"
        
        result = "time (s): $exact_duration \n " \
         "Ins Current (mA): $instantanious_current \n"  \
          "\nSamples: $number_of_samples  \n" \
          "\nConsumed Energy (mAs): $energy_consumption_mA_seconds \n" \
          "\nConsumed Energy (mAh): $energy_consumption_mA_h \n" \
          "\nConsumed Energy (mWs): $energy_consumption_mW_seconds  \n" \
          "\nConsumed Energy (mWh): $energy_consumption_mW_h \n" \
          "\nAvg power (mW): $average_power" \
          "\nAvg Current (mA): $average_current" \
         "\nAvg Voltage (V): $average_voltage" \
         "\nExp Batt Life (hrs for 1000mAh battery): NOT COMPUTED " \
        echo  result
    
}
"""







"""
CurrentToWrite=0
        VoltageToWrite=0

        is_header=1
        is_first_data=1
        counter=0
        while IFS=, read -r  timeStamp USB_Current USB_voltage  ; do
            if [ "$is_header" -ne "0" ]; then
                echo "--- Reading header $sample_time, $USB_Current and  $USB_voltage "
                echo "--- Creating the file $new_mesurement_file" 
                echo "Time(ms),USB Current(mA),USB Voltage(V)," > $new_mesurement_file
                is_header=0
            else
                if [ "$is_first_data" -ne "0" ]; then
                    is_first_data=0
                    timeStampToWrite=$timeStamp
                fi
                #echo  "Before CurrentToWrite = $CurrentToWrite, USB_Current=$USB_Current, VoltageToWrite= $VoltageToWrite, USB_voltage =  $USB_voltage" 
                CurrentToWrite=$(awk -v CurrentToWrite=$CurrentToWrite -v USB_Current=$USB_Current 'BEGIN {print  (CurrentToWrite + USB_Current); exit}')#$(echo $CurrentToWrite + $USB_Current | bc ) #$((CurrentToWrite + USB_Current))
                USB_voltage=$(echo $USB_voltage |   tr -d '\r' ) 
                USB_voltage=${USB_voltage::-1} #-1 is to remove the comma
                VoltageToWrite=$(awk -v VoltageToWrite=$VoltageToWrite -v USB_voltage=$USB_voltage  'BEGIN {print  VoltageToWrite + USB_voltage; exit}')#$(echo $VoltageToWrite + ${USB_voltage::-1} | bc ) #$((VoltageToWrite + USB_voltage))
                #echo "After CurrentToWrite = $CurrentToWrite, USB_voltage =  $USB_voltage,  CurrentToWrite= $CurrentToWrite ,VoltageToWrite= $VoltageToWrite " 
               
                if [ "$((counter % 125))" -eq "0" ]; then
                    CurrentToWrite=$(awk -v CurrentToWrite=$CurrentToWrite 'BEGIN { print CurrentToWrite/125 }') # $(bc -l <<< '$CurrentToWrite/125') #$((CurrentToWrite / 125))
                    VoltageToWrite=$(awk -v VoltageToWrite=$VoltageToWrite 'BEGIN { print VoltageToWrite/125 }') #$(bc -l <<< '$VoltageToWrite/125') #$((VoltageToWrite / 125))
                    #timeStampToWrite=$(echo $timeStampToWrite + $timeStamp | bc ) #$((timeStampToWrite + timeStamp))
                    #timeStampToWrite=$(bc -l <<< '$timeStampToWrite/2') # $((timeStampToWrite / 2))
                    timeStampToWrite=$(awk -v timeStampToWrite=$timeStampToWrite -v timeStamp=$timeStamp 'BEGIN { print (timeStamp+timeStampToWrite)/2 }')
                    echo "$timeStampToWrite,$CurrentToWrite,$VoltageToWrite" >> $new_mesurement_file
                    echo " Mesurement at time $timeStamp ms, USB Current: $USB_Current mA,  USB Voltage: $USB_voltage V"
                    echo " Mesurement to write to file at time $timeStampToWrite ms, USB Current: $CurrentToWrite mA,  USB Voltage: $VoltageToWrite V"
                    CurrentToWrite=0
                    VoltageToWrite=0
                    timeStampToWrite=timeStamp
                fi  
   
                counter=$((counter + 1))
            fi      
        done < $mesurement_file
"""

