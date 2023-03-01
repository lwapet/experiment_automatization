#Code written by reading the Monsoon API documentation http://msoon.github.io/powermonitor/Python_Implementation/docs/API.pdf
#parameters : 
    # sys.argv[1] the function code to execute during experiements:
      # 1 is for Monsoon powermeter calibration
    # sys.argv[from 2 to n] Eventually, argument related to the function to execute
      ## for function code 1, ie the battery drainer app
      # sys.argv[2] = output voltage
      # sys.argv[3] = csv output_file
      # 
#import monsoon.LVPM as LVPM
import numpy as np
import libusb1 as libus
import sys as sys

import Monsoon.HVPM as HVPM
import Monsoon.sampleEngine as sampleEngine
import Monsoon.Operations as op
print ("--- Inside the monsoon_power_meter, arg function: ", sys.argv[1])
# Connects to the current device, returning a MonkeyDevice object
if sys.argv[1] == '1':



#Mon = LVPM.Monsoon()
Mon = HVPM.Monsoon()
Mon.setup_usb()
print("Creating the Monsoon engine")
Mon.setVout(3.70)
engine = sampleEngine.SampleEngine(Mon)
print("Configuring channels the Monsoon engine")

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

print("Configuring output ")
engine.enableCSVOutput("testing_monsoon_on_mouse.csv")
engine.ConsoleOutput(True)
numSamples = 50  #sample for one second 5000 is the maximum supported value.

print("Starting sampling")
engine.startSampling(numSamples)
samples = engine.getSamples()

#Samples are stored in order, indexed sampleEngine.channels values
for i in range(0, len(samples[sampleEngine.channels.timeStamp])-1):
    timeStamp = samples[sampleEngine.channels.timeStamp][i]
    Current = samples[sampleEngine.channels.USBCurrent][i]
    print("USB current at time " + repr(timeStamp) + " is: " + repr(Current) + "mA")
