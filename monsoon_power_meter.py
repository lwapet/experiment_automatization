#Code written by reading the Monsoon API documentation http://msoon.github.io/powermonitor/Python_Implementation/docs/API.pdf
#parameters : 
    # sys.argv[1] the function code to execute during experiements:
      # 1 is for Monsoon powermeter calibration 
    # sys.argv[from 2 to n] Eventually, argument related to the function to execute
      ## for function code 1, ie Monsoon powermeter calibration
      # sys.argv[2] = output voltage
      # sys.argv[3] = calibration_duration
      # sys.argv[4] = csv output_file in seconds
      ## For function code 2  
      # sys.argv[2] = output voltage
      # sys.argv[3] = experiment_duration
      # sys.argv[4] = csv output_file in seconds
      # sys.argv[5] = summry output  file
      # note n_sampling = 5000 * duration 
#import monsoon.LVPM as LVPM
import numpy as np
import libusb1 as libus
import sys as sys

import Monsoon.HVPM as HVPM
import Monsoon.sampleEngine as sampleEngine
import Monsoon.Operations as op
tag = "powermeter script : "


def run_power_meter(engine, V_out, calibration_duration, csv_output_file):
    number_of_samples = int(calibration_duration) * 5000 # because the powermeter capture 1 sample every 200 useconds 
                                                     #thus 5000 mesurements per seconds
    Mon = HVPM.Monsoon()
    Mon.setup_usb()
    print(tag + "Creating the Monsoon engine")
    Mon.setVout(V_out)
    print(tag + "Configuring channels the Monsoon engine")

    #Disable Main channels
    engine.disableChannel(sampleEngine.channels.MainCurrent)
    engine.disableChannel(sampleEngine.channels.MainVoltage)

    #Enable USB channels
    engine.enableChannel(sampleEngine.channels.USBCurrent)
    engine.enableChannel(sampleEngine.channels.USBVoltage)

    #Enable Aux channel (
    #me I commented this because when enable it on graphical interface, usb channel is automatically disabled
    # engine.enableChannel(sampleEngine.channels.AuxCurrent)

    #Set USB Passthrough mode to 'on,' since it defaults to 'auto' and will turn off when
    #sampling mode begins.
    Mon.setUSBPassthroughMode(op.USB_Passthrough.On)

    print(tag + "Configuring output to : " + csv_output_file)
    #engine.enableCSVOutput(csv_output_file)
    #engine.ConsoleOutput(True)
    engine.disableCSVOutput()
    engine.ConsoleOutput(False)


    print(tag + "Starting sampling; number of sample = ", number_of_samples)
    engine.startSampling(number_of_samples)
    samples = engine.getSamples()
    #Samples are stored in order, indexed sampleEngine.channels values

    with open(csv_output_file,'w') as file:
      string_to_write_in_file = "Time(ms),USB Current(mA),USB Voltage(V),"
      #print(" --- Actual line to write in file:", string_to_write_in_file)
      file.write(str(string_to_write_in_file))
      timeStampToWrite= samples[sampleEngine.channels.timeStamp][0]
      CurrentToWrite=0
      VoltageToWrite=0
      for i in range(0, len(samples[sampleEngine.channels.timeStamp])-1):  # we write 40 samples per second  (125 = 5000/40)
        timeStamp = samples[sampleEngine.channels.timeStamp][i]
        Current = samples[sampleEngine.channels.USBCurrent][i]
        Voltage = samples[sampleEngine.channels.USBVoltage][i]  

        CurrentToWrite = CurrentToWrite + Current
        VoltageToWrite = VoltageToWrite + Voltage
        if (i % 125 == 0):
          timeStampToWrite = (timeStampToWrite +  samples[sampleEngine.channels.timeStamp][i])/2
          CurrentToWrite = CurrentToWrite / 125
          VoltageToWrite = VoltageToWrite / 125
          #print(tag + " Mesurement at time " + repr(timeStamp) + ", USB Current: " + repr(Current) + " mA, USBVoltage" +  repr(Voltage) + " V")
          #print(tag + " Mesurement to write in file at time " + repr(timeStampToWrite) + ", USB Current: " + repr(CurrentToWrite) + " mA, USBVoltage" +  repr(VoltageToWrite) + " V")
          file.write("\n" + repr(timeStampToWrite) + "," + repr(CurrentToWrite) + "," + repr(VoltageToWrite) + ",")
          timeStampToWrite = samples[sampleEngine.channels.timeStamp][i] 
          CurrentToWrite=0
          VoltageToWrite=0
      file.write('\n')
  
    print(" returning " + str(len(samples[sampleEngine.channels.timeStamp])) + " samples after experiments")
    return samples


#step 4: function to compute efficiently the diagonal of a product of tow vectors. 
def diag_of_product(A, B):
    print ("** START computing diag_of_product of A and B  ")
    print ("A = ", A)
    print ("B = ", B)
    result = (np.einsum('ij,ji->i', A,B)).T  # einsum is a workaround obtained from stack overflow 
    print ("** END computing diag_of_product of A and B , result = ", result)
    return result

def compute_summary_string_data(samples):
  print( tag + "Computing powermeter summary result")
  result = ""
  # Computing the number of sample
  number_of_samples = len(samples[sampleEngine.channels.timeStamp])
  print(" Number of samples = ", number_of_samples)
  # Computing the exact total experiment time in seconds
  exact_duration =  samples[sampleEngine.channels.timeStamp][number_of_samples-1] - samples[sampleEngine.channels.timeStamp][0]
  # Computing average Energy
  energy_consumption_mW_seconds = 0
  energy_consumption_mA_seconds = 0
  energy_consumption_w_h = 0
  energy_consumption_mA_h = 0
  number_of_samples_used_to_compute_energy = 0
  for i in range(0, number_of_samples):
    Current = samples[sampleEngine.channels.USBCurrent][i]
    Voltage = samples[sampleEngine.channels.USBVoltage][i]
    if i % 5000 == 2500: # because we integrete the energy at unit of time ie second per second, not at every sampling (200us), 
      energy_consumption_mW_seconds = energy_consumption_mW_seconds + Current * Voltage 
      energy_consumption_mA_seconds = energy_consumption_mA_seconds + Current
      number_of_samples_used_to_compute_energy = number_of_samples_used_to_compute_energy + 1
  
  print( tag + " We computed the energy on " + str(number_of_samples_used_to_compute_energy) + " samples")
  energy_consumption_mW_h = energy_consumption_mW_seconds / 3600
  energy_consumption_mA_h = energy_consumption_mA_seconds / 3600

  # Computing average power
  average_current=0
  average_voltage=0
  for i in range(0, number_of_samples):
      average_current = average_current +  samples[sampleEngine.channels.USBCurrent][i]
      average_voltage = average_voltage + samples[sampleEngine.channels.USBVoltage][i]

  average_current = average_current/number_of_samples
  average_voltage = average_voltage/number_of_samples
  average_power = average_current*average_voltage
  average_power_=np.mean( np.array(samples[sampleEngine.channels.USBCurrent])) * np.mean( np.array(samples[sampleEngine.channels.USBVoltage])) 
  print(tag + "average_power = ", average_power)
  print(tag + "average_power with numpy  arrays = ", average_power_)
  

  result = ("time (s): " + repr(exact_duration) + 
         "\nIns Current (mA):" + repr(samples[sampleEngine.channels.USBCurrent][number_of_samples//2]) + ## for floor division, just to have an idea of the current during experiment, I don't know if it the same explanation in powermeter summary window.
          "\nSamples: " + repr(number_of_samples) +
          "\nConsumed Energy (mAs): " + repr(energy_consumption_mA_seconds) +  
          "\nConsumed Energy (mAh): " + repr(energy_consumption_mA_h) +  
          "\nConsumed Energy (mWs): " + repr(energy_consumption_mW_seconds) +  
          "\nConsumed Energy (mWh): " + repr(energy_consumption_mW_h) +       
          "\nAvg power (mW): " + repr(average_power) + 
          "\nAvg Current (mA): " + repr(average_current) +  
          "\nAvg Voltage (V): " + repr(average_voltage) +    
          "\nExp Batt Life (hrs for 1000mAh battery): NOT COMPUTED " ) 
  print (tag + "Summary Result = "+ result)
  return result
  #


print (tag + "--- Inside the monsoon_power_meter, arg function: ", sys.argv[1])
# Connects to the current device, returning a MonkeyDevice object
if sys.argv[1] == '1':
    #Mon = LVPM.Monsoon()
    V_out = float(sys.argv[2]) # 3.70 on the monsoon power meter by default
    calibration_duration =  sys.argv[3]
    print(tag + "calibration duration = ", calibration_duration)
    csv_output_file = sys.argv[4] # "testing_monsoon_on_mouse.csv"
    
    Mon = HVPM.Monsoon()
    Mon.setup_usb()
    print(tag + "Creating the Monsoon engine")
    engine = sampleEngine.SampleEngine(Mon)
    run_power_meter(engine, V_out, calibration_duration, csv_output_file)
    print(tag + "Power meter calibration okay")

elif sys.argv[1] == '2': # real experiements exected summary 
    #Mon = LVPM.Monsoon()
    V_out = float(sys.argv[2]) # 3.70 on the monsoon power meter by default
    calibration_duration =  sys.argv[3]
    print(tag + "Experiment duration = ", calibration_duration)
    csv_output_file = sys.argv[4] # "testing_monsoon_on_mouse.csv"
    summary_output_file = sys.argv[5]
    
    Mon = HVPM.Monsoon()
    Mon.setup_usb()
    print(tag + "Creating the Monsoon engine")
    engine = sampleEngine.SampleEngine(Mon)
    sample_result = run_power_meter(engine, V_out, calibration_duration, csv_output_file)
    print( tag + " Total nomber of sample measured : " , len(sample_result[sampleEngine.channels.timeStamp]))
    ### TO DO Look How to get summary panel data with monsoon, having samples. 
    summary_data = compute_summary_string_data(sample_result)

    f = open(summary_output_file , "w")
    f.write(summary_data)
    f.close()
