# Remote Dell Command Update 2.0 - Kirtan Bhatt 

Prerequisites:

- PsExec.exe must be installed and in the same directory 
  as RemoteDCU.exe (sys.internals.com)

Overview:

This script automates Dell Command Update functions for driver, BIOS, and 
firmware updates. Given a computer name, the script will first enable the 
computer's PS Remoting setting for the process to successfully start. From 
there, it will install the DCU Application (if already installed, it will 
be removed and new version installed). Then it will update the DCU-CLI and 
scan for any updates necessary. A list of all updates will be shown, and 
from there the user is prompted to either apply all updates, or update the 
firmware, drivers, and BIOS individually (once each run). The script will 
perform as requested by user, and once the update has completed, the user 
is prompted for the remote PC to reboot for the updates to be applied. If 
not, the updates will be applied on the next restart. Given the user selects
to reboot the computer, the script will ping the computer until it has 
completed the restart in order to reboot once more, to apply any lingering
BIOS/application updates.

Note:

- If you are getting a "Not Digitally Signed Error", please right click
  on the script file, click "Properties", and check "Unblock" at the bottom

- The DCU 5.0.0 Upgrade Update may still show up after script finishes, this 
  is the application itself's update and it will be completed in the background 
  process and applied after a future restart
