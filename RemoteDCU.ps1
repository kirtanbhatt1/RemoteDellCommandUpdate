# v. 1.0 Original (Kirtan)
# v. 1.1 Add Output line 69 (CJB)

# Function for User Menu Interface
function Show-Menu
{
    param (
       [string]$Title = 'Dell Command Update Options'
    )
    # Menu Title
    Write-Host "`n===================== $Title ================="
    Write-Host "`n    1: Apply All Updates. (Recommended)"
    Write-Host "    2: Update the Drivers."
    Write-Host "    3: Update the Firmware."
    Write-Host "    4: Update the BIOS." 
    Write-Host "    5: Quit. "
}

# Function for Main DCU Commands
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
    Write-Host "`nStep 1: Installing/Updating DCU..."
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

    Get-Content \\$ComputerName\c$\Temp\dcuscan.log | Select-String -pattern Urgent,Recommended,Optional

    #CJB END

    # Ask User if they wish to Apply All Updates, only BIOS, only Firmware, or only Drivers
    Show-Menu

    $input1 = Read-Host "`nPlease make a selection"
    switch ($input1)
    {
        '1' {
            Invoke-Command -ComputerName $computerName -ScriptBlock {
                Write-Host "Please wait ..."
                Start-Process $using:dcuPathOnRemote -ArgumentList "/applyupdates" -Wait

            }
        }
        '2' {
            Invoke-Command -ComputerName $computerName -ScriptBlock {
                Write-Host "Please wait ..."
                Start-Process $using:dcuPathOnRemote -ArgumentList "/applyupdates -updatetype=driver" -Wait

            }
        }
        '3' {
            Invoke-Command -ComputerName $computerName -ScriptBlock {
                Write-Host "Please wait ..."
                Start-Process $using:dcuPathOnRemote -ArgumentList "/applyupdates -updatetype=firmware" -Wait

            }
        }
        '4' {
            Invoke-Command -ComputerName $computerName -ScriptBlock {
                Write-Host "Please wait ..."
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
 
# MAIN DRIVER

# Prompt the user to enter the computer name
$computerName = Read-Host "`nEnter the remote computer name"

$command = ".\PsExec.exe \\$computerName -h -s powershell.exe Enable-PSRemoting -Force"
    Invoke-Expression -Command $command


# Run Dell Command Update
RunDellCommandUpdate -ComputerName $computerName

# Restart computer
$restartInput = Read-Host "`nComputer may need to restart to apply changes. Do you wish to continue? ('Y' or 'N')"

if ($restartInput -eq 'Y' -or $restartInput -eq 'y') {
    Invoke-Command -ComputerName $computerName -ScriptBlock {
        Start-Process Shutdown -ArgumentList "/r /f" -Wait
    }
} else {
    Write-Host "`nRestart cancelled. Updates will apply on the next reboot."
}

# Done
Write-Host "`nRemote update completed."