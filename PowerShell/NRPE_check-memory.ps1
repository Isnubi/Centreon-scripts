#Requires -RunAsAdministrator
#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-memory.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.07.05
# RELEASE            :     v1.0.0
# USAGE SYNTAX       :     .\NRPE_check-memory.ps1
#
# SCRIPT DESCRIPTION :     This script is used to check the memory usage of a host for NRPE.
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

function Get-MemoryUsage {
    <#
    .SYNOPSIS
    Get the memory usage of a host.
    .DESCRIPTION
    This function is used to get the memory usage of a host.
    .INPUTS
    None.
    .OUTPUTS
    System.String: Memory usage of the host.
    .EXAMPLE
    Get-MemoryUsage
    #>
    begin { $compObject = Get-WmiObject -Class Win32_OperatingSystem }
    process {
        $memory = ((($compObject.TotalVisibleMemorySize - $compObject.FreePhysicalMemory) * 100) / $compObject.TotalVisibleMemorySize)
        $memory = [Math]::Round($memory, 2)
    }
    end { return $memory }
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

$memoryUsage = Get-MemoryUsage
if ($memoryUsage -ge 90) {
    $outLog = @(Write-Output "CRITICAL - Memory usage", "Memory usage is at $memoryUsage%")
    Write-Output $outLog
    exit 2
} elseif ($memoryUsage -lt 90 -and $memoryUsage -ge 80) {
    $outLog = @(Write-Output "WARNING - Memory usage", "Memory usage is at $memoryUsage%")
    Write-Output $outLog
    exit 1
} else {
    $outLog = @(Write-Output "OK - Memory usage", "Memory usage is at $memoryUsage%")
    Write-Output $outLog
    exit 0
}