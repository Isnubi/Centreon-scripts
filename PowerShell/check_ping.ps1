param(
    [Parameter(Mandatory = $true, Position = 0)]
    [String] $Hostname
)
#==========================================================================================
#
# SCRIPT NAME        :     check_ping.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.07.05
# RELEASE            :     v1.0.0
# USAGE SYNTAX       :     .\check_ping.ps1
#
# SCRIPT DESCRIPTION :     This script is used to check the ping of a host for NRPE.
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

function Get-HostPing {
    <#
    .SYNOPSIS
    Get the ping of a host.
    .DESCRIPTION
    This function is used to get the ping of a host.
    .INPUTS
    System.String: Hostname of the host.
    .OUTPUTS
    System.String: Ping of the host.
    .EXAMPLE
    Get-HostPing -Hostname "127.0.0.1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Hostname
    )
    begin {}
    process {
        if ((Test-Connection -ComputerName $Hostname -Count 5 -Quiet) -eq $true) {
            return "OK"
        } else {
            return "CRITICAL"
        }
    }
    end {}
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

$pingStatus = Get-HostPing -Hostname $Hostname
if ($pingStatus -eq "OK") {
    $outLog = @("OK - Ping is OK", "Ping is OK to $Hostname")
    Write-Output $outLog
    exit 0
} elseif ($pingStatus -eq "CRITICAL") {
    $outLog = @("CRITICAL - Ping is CRITICAL", "Ping is CRITICAL to $Hostname")
    Write-Output $outLog
    exit 2
} else {
    $outLog = @("UNKNOWN", "Unknown error occured")
    Write-Output $outLog
    exit 3
}