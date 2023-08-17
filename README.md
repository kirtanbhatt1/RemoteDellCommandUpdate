# Remote Dell Command Update 2.0 - Kirtan Bhatt 

Prerequisites:

- PsExec.exe must be installed and in the same directory 
  as RemoteDCU.exe (sys.internals.com)

Overview:

This script automates Dell Command Update functions for driver, BIOS, and firmware updates.
Given a computer name, the script will first enable the computer's PS Remoting setting for 
the process to successfully start. From there, it will install the DCU Application (if already 
installed, it will be removed and new version installed). Then it will update the DCU-CLI and 
scan for any updates necessary. A list of all updates will be shown, and from there the user is 
prompted to either apply all updates, or update the firmware, drivers, and BIOS individually 
(once each run). The script will perform as requested by user, and once the update has completed, 
the user is prompted for the remote PC to reboot for the updates to be applied. If not, the updates 
will be applied on the next restart.

