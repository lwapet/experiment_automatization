from com.android.monkeyrunner import MonkeyRunner, MonkeyDevice
import sys as sys
#template file downloaded from this link https://developer.android.com/studio/test/monkeyrunner
#parameters : 
    # sys.argv[1] the function code to execute during experiements:
      # 1 is for the battery drainer app
    # sys.argv[from 2 to n] Eventually, argument related to the function to execute
      ## for function code 1, ie the battery drainer app
      # sys.argv[2] = package name
      # sys.argv[3] = activity name



print ("--- Inside the monkey_runner, arg function: ", sys.argv[1])
# Connects to the current device, returning a MonkeyDevice object
device = MonkeyRunner.waitForConnection()
if sys.argv[1] == '1': #   for the battery drainer app
    # sets a variable with the package's internal name
    package = sys.argv[2]
    # sets a variable with the name of an Activity in the package
    activity = sys.argv[3]
    # sets the name of the component to start
    runComponent = package + '/' + activity
    print("---  Ready to process: ", runComponent)

    print("---  Touching the device " )
    device.touch(0, 0, MonkeyDevice.DOWN_AND_UP)
    MonkeyRunner.sleep(5) # DON'T MODIFY
    print("--- Pressing TAB (To move to start)" )
    device.press("KEYCODE_TAB", MonkeyDevice.DOWN_AND_UP)
  
    MonkeyRunner.sleep(5)
    print("---  Pressing the start button" )
    device.press("KEYCODE_ENTER", MonkeyDevice.DOWN_AND_UP)
    
    # Presses the Menu button
    # device.press('KEYCODE_MENU', MonkeyDevice.DOWN_AND_UP)

# Takes a screenshot
#result = device.takeSnapshot()

# Writes the screenshot to a file
#result.writeToFile('C:\Users\lavoi\opportunist_task_on_android\scripts_valuable_files\experiment_automatization\shot5.png','png')

"""
print("calling the monkey runner script")
# Connects to the current device, returning a MonkeyDevice object
device = MonkeyRunner.waitForConnection()

print("running the package")
# Installs the Android package. Notice that this method returns a boolean, so you can test
# to see if the installation worked.
# device.installPackage('C:\Users\lavoi\opportunist_task_on_android\git_repositories\app_to_drain_battery.apk')

# sets a variable with the package's internal name
package = 'com.opportunistask.scheduling.benchmarking_app_to_test_big_cores'
 1 com.opportunistask.scheduling.benchmarking_app_to_test_big_cores.MainActivity com.opportunistask.scheduling.benchmarking_app_to_test_big_cores
# sets a variable with the name of an Activity in the package
activity = 'com.opportunistask.scheduling.benchmarking_app_to_test_big_cores.MainActivity'

# sets the name of the component to start
runComponent = package + '/' + activity

# Runs the component
device.startActivity(component=runComponent)

# Presses the Menu button
#device.press('KEYCODE_MENU', MonkeyDevice.DOWN_AND_UP)
print("taking snapshot")

# Takes a screenshot
result = device.takeSnapshot()

# Writes the screenshot to a file
result.writeToFile('C:\Users\lavoi\opportunist_task_on_android\scripts_valuable_files\experiment_automatization\shot1.png','png')
"""