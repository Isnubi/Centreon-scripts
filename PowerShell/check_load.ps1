#Requires -RunAsAdministrator
#==========================================================================================
#
# SCRIPT NAME        :     check_load.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.07.05
# RELEASE            :     v1.0.0
# USAGE SYNTAX       :     .\check_load.ps1
#
# SCRIPT DESCRIPTION :     This script is used to check the CPU load of a host for NRPE.
#
#==========================================================================================

#                 - RELEASE NOTES -
# v1.0.0  2022.10.21 - Louis GAMBART - Initial version
#
#==========================================================================================


###################
#                 #
#  I - VARIABLES  #
#                 #
###################

# error clear
$error.Clear()


####################
#                  #
#  II - FUNCTIONS  #
#                  #
####################

function Get-CPULoad {
    <#
    .SYNOPSIS
    Get the CPU load of a host.
    .DESCRIPTION
    This function is used to get the CPU load of a host.
    .INPUTS
    None.
    .OUTPUTS
    System.String: CPU load of the host.
    .EXAMPLE
    Get-CPULoad
    #>
    begin { $compObject = Get-WmiObject -Class CIM_Processor }
    process {
        $cpu = $compObject.LoadPercentage | Measure-Object -Average
        $cpu = [Math]::Round($cpu.Average, 2)
    }
    end { return $cpu }
}


#########################
#                       #
#  III - ERROR HANDLER  #
#                       #
#########################

# trap errors
trap {
    Write-Output "ERROR: An error has occured and the script can't run: $_"
    exit 2
}


###########################
#                         #
#  IV - SCRIPT EXECUTION  #
#                         #
###########################

$cpuLoad = Get-CPULoad
if ($cpuLoad -ge 2) {
    $outLog = @(Write-Output "CRITICAL - CPU usage", "CPU usage is at $cpuUsage%")
    Write-Output $outLog
    exit 2
} elseif ($cpuUsage -lt 2 -and $cpuUsage -ge 1) {
    $outLog = @(Write-Output "WARNING - CPU usage", "CPU usage is at $cpuUsage%")
    Write-Output $outLog
    exit 1
} else {
    $outLog = @(Write-Output "OK - Memory CPU", "CPU usage is at $cpuUsage%")
    Write-Output $outLog
    exit 0
}