# Dell Command Update Script 2.0 - Kirtan Bhatt
#    - Includes Installation of DCU Application 
#    - DCU will be uninstalled and reinstalled if old version is found
#    - Includes double restart of computer after updates.

function Show-Menu
{
    param (
       [string]$Title = 'Dell Command Update Options'
    )
    # Menu Title
    Write-Host "`n ===================== $Title ====================="
    Write-Host "`n    1: Apply All Updates. (Recommended)"
    Write-Host "    2: Update the Drivers."
    Write-Host "    3: Update the Firmware."
    Write-Host "    4: Update the BIOS." 
    Write-Host "    5: Quit. "
}

function RunDellCommandUpdate
{
    param (
        [string]$computerName
    )


    # Step 1: Determine the correct path for dcu-cli.exe based on Program Files or Program Files (x86)
    $dcuPath = "C:\Program Files\Dell\CommandUpdate\dcu-cli.exe"
    $dcuPathOnRemote = Invoke-Command -ComputerName $computerName -ScriptBlock {
        param (
            [string]$dcuPath
        )
        $remotePath = $dcuPath
        if (!(Test-Path $remotePath))
        {
            $remotePath = "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe"
        }
        $remotePath
    } -ArgumentList $dcuPath

    # If Path is empty, there is no DCU file
    if ([string]::IsNullOrWhiteSpace($dcuPathOnRemote))
    {
        Write-Host "The Dell Command Update path was not found on the remote computer."
        exit
    }

    # Step 2: Install/update DCU
    Write-Host "`nStep 1: Updating DCU-CLI..."
    Invoke-Command -ComputerName $computerName -ScriptBlock {
        param (
            [string]$dcuPathOnRemote
        )
        Start-Process $dcuPathOnRemote -ArgumentList "/s /f" -Wait
    } -ArgumentList $dcuPathOnRemote

    # Step 3: Check for outdated drivers
    Write-Host "Step 2: Scanning for outdated drivers..."
    Invoke-Command -ComputerName $computerName -ScriptBlock {
        param (
            [string]$dcuPathOnRemote
        )
        Start-Process $dcuPathOnRemote -ArgumentList "/scan -outputLog=C:\Temp\dcuscan.log" -Wait
    } -ArgumentList $dcuPathOnRemote

    #CJB HERE

    #Outputs needed updates

    Get-Content \\$ComputerName\c$\Temp\dcuscan.log | Select-String -pattern Urgent,Recommended,Optional

    #CJB END

    # Ask User if they wish to Apply All Updates, only BIOS, only Firmware, or only Drivers
    Show-Menu

    $input1 = Read-Host "`nPlease make a selection"
    switch ($input1)
    {
        '1' {
            Invoke-Command -ComputerName $computerName -ScriptBlock {
                Write-Host "`nInstalling All Updates. Please wait ..."
                Start-Process $using:dcuPathOnRemote -ArgumentList "/applyupdates" -Wait

            }
        }
        '2' {
            Invoke-Command -ComputerName $computerName -ScriptBlock {
                Write-Host "`nInstalling Driver Updates. Please wait ..."
                Start-Process $using:dcuPathOnRemote -ArgumentList "/applyupdates -updatetype=driver" -Wait

            }
        }
        '3' {
            Invoke-Command -ComputerName $computerName -ScriptBlock {
                Write-Host "`nInstalling Firmware Updates. Please wait ..."
                Start-Process $using:dcuPathOnRemote -ArgumentList "/applyupdates -updatetype=firmware" -Wait

            }
        }
        '4' {
            Invoke-Command -ComputerName $computerName -ScriptBlock {
                Write-Host "`nInstalling BIOS Updates. Please wait ..."
                Start-Process $using:dcuPathOnRemote -ArgumentList "/applyupdates -updatetype=bios" -Wait

            }
        }
        '5' {
            # Do nothing for 'Quit' option
            Write-Host "`nUpdate cancelled."
            exit
        }
    }
}

# Prompt the user to enter the computer name
$computerName = Read-Host "`nEnter the remote computer name"


# Enable PS-Remoting on remote Computer

$command = ".\PsExec.exe \\$computerName -h -s powershell.exe Enable-PSRemoting -Force"
    Invoke-Expression -Command $command


# Copy Necessary Files into Computer's Temp folder
Write-Host "`nCopying Files..."

Copy-Item "\\data1\AMR\ATS\Software\Other\DELL\Dell Client Command Suite\Command Update\Dell-Command-Update-Application_P5R35_WIN_4.1.0_A00.EXE" -Destination "\\$computerName\C$\Temp"

Copy-Item "\\data1\AMR\ATS\Software\Other\DELL\Dell Client Command Suite\Command Update\AppliedMedicalClient.xml" -Destination "\\$computerName\C$\Temp"

# Next few commands are ran on remote computer
Invoke-Command -ComputerName $computerName -ScriptBlock {

    # Removing previous versions of DCU
    Write-Host "`nRemoving Previous Versions. Please wait..."

    Start-Process -FilePath "MsiExec.exe" -ArgumentList "/X{EC542D5D-B608-4145-A8F7-749C02BE6D94} /QN /NoRestart" -Wait

    Start-Process -FilePath "MsiExec.exe" -ArgumentList "/X{5669AB71-1302-4412-8DA1-CB69CD7B7324} /QN /NoRestart" -Wait

    # Install DCU
    Write-Host "`nInstalling Dell Command Update..."

    Start-Process -FilePath "C:\Temp\Dell-Command-Update-Application_P5R35_WIN_4.1.0_A00.EXE" -ArgumentList "/S /L=C:\TEMP\DellCommandUpdate.log" -Wait

    # Install the policy file
    Write-Host "Installing policy file..."

    Start-Process -FilePath "C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe" -ArgumentList "/configure -importSettings=`"C:\Temp\AppliedMedicalClient.xml`"" -Wait

    Write-Host "`nDCU Installation Complete."

}

# Run Update Menu
RunDellCommandUpdate -ComputerName $computerName

# Restart computer
$restartInput = Read-Host "`nComputer may need to restart to apply changes. Do you wish to continue? ('Y' or 'N')"

if ($restartInput -eq 'Y' -or $restartInput -eq 'y') {
    
    # First restart
    Restart-Computer -ComputerName $computerName -Force

    # Second restart 
    Write-Host "Please wait..."
   
    Start-Sleep -Seconds 30

    do {
        $pingResult = Test-Connection -ComputerName $computerName -Count 1 -ErrorAction SilentlyContinue
        if ($pingResult -eq $null) 
            {
                Write-Host "Waiting for $computerName to ping..."
                Start-Sleep -Seconds 10  # Adjust the wait time as needed
            }
    } while ($pingResult -eq $null)

 
    Write-Host "$computerName responded to ping. Starting next restart."
    Restart-Computer -ComputerName $computerName -Force

    
} else {
    Write-Host "`nRestart cancelled. Updates will apply on the next reboot."
}

# Done
Write-Host "`nRemote update complete."
