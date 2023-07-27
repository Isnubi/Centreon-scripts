#==========================================================================================
#
# SCRIPT NAME        :     NRPE_check-group-treshold.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.07.10
# RELEASE            :     v2.0.0
# USAGE SYNTAX       :     .\NRPE_check-group-treshold.ps1
#
# SCRIPT DESCRIPTION :     This script is used to check if an AD group has reached a threshold of users in it.
#
#==========================================================================================

#                 - RELEASE NOTES -
# v1.0.0  2023.07.10 - Louis GAMBART - Initial version
# v2.0.0  2023.07.26 - Louis GAMBART - Rework the script to use my new template
#
#==========================================================================================


###################
#                 #
#  I - VARIABLES  #
#                 #
###################

# clear error variable
$error.clear()

# group name
[String] $ADGroupName = ""

# threshold
[Int] $warningThreshold = 40
[Int] $criticalThreshold = 50

# UAC value
[Int] $UAC = ""

# centreon exit code
# 0 = OK
# 1 = WARNING
# 2 = CRITICAL
# 3 = UNKNOWN


####################
#                  #
#  II - FUNCTIONS  #
#                  #
####################

function Get-Datetime {
    <#
    .SYNOPSIS
    Get the current date and time
    .DESCRIPTION
    Get the current date and time, optionally formatted as a string
    .INPUTS
    System.String: The format string
    .OUTPUTS
    System.String: The formatted date and time
    .EXAMPLE
    Get-Datetime -Format "yyyy-MM-dd HH:mm:ss"
    2021-07-04 12:00:00
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Format
    )
    begin {}
    process {
        if ([string]::IsNullOrEmpty($Format)) {
            return [DateTime]::Now
        }
        else {
            return [DateTime]::Now.ToString($format)
        }
    }
    end {}
}


function Get-SystemType {
    <#
    .SYNOPSIS
    Get the system type
    .DESCRIPTION
    Get the system type
    .INPUTS
    None
    .OUTPUTS
    System.String: The system type
    .EXAMPLE
    Get-SystemType
    Server
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param()
    begin { $osInfo = Get-CimInstance Win32_OperatingSystem }
    process {
        if ($osInfo.ProductType -eq 1) { return "Workstation" }
        elseif ($osInfo.ProductType -eq 2 -or $osInfo.ProductType -eq 3) { return "Server" }
        else { return "Unknown" }
    }
    end {}
}


function Write-Log {
    <#
    .SYNOPSIS
    Write log message in the console
    .DESCRIPTION
    Write log message in the console
    .INPUTS
    System.String: The message to write
    System.String: The log level
    .OUTPUTS
    None
    .EXAMPLE
    Write-Log "Hello world" "Verbose"
    VERBOSE: Hello world
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet('Error', 'Warning', 'Information', 'Verbose', 'Debug')]
        [string]$LogLevel = 'Information'
    )
    begin {}
    process {
        switch ($LogLevel) {
            'Error' { Write-Error $Message -ErrorAction Stop }
            'Warning' { Write-Warning $Message -WarningAction Continue }
            'Information' { Write-Information $Message -InformationAction Continue }
            'Verbose' { Write-Verbose $Message -Verbose }
            'Debug' { Write-Debug $Message -Debug Continue }
            default { throw "Invalid log level: $_" }
        }
    }
    end {}
}


function Get-ADAllGroupAndMember {
    <#
    .SYNOPSIS
    Get all AD groups and members recursively
    .DESCRIPTION
    Get all AD groups and members recursively
    .INPUTS
    System.String: The AD group name
    .OUTPUTS
    User list
    .EXAMPLE
    Get-ADAllGroupAndMember -ADGroupName "GDL-TEST"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ADGroupName
    )
    begin {}
    process {
        foreach ($name in $ADGroupName) {
            Get-ADGroupMember $name
            Get-ADGroupMember $name | Where-Object {$_.objectClass -eq "group"} | Get-ADAllGroupAndMember
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

try { Import-Module -Name 'ActiveDirectory' }
catch {
    $outLog = @("UNKNOWN: Unable to import the ActiveDirectory module: $_")
    Write-Output $outLog
    exit 3
}

$count = (Get-ADAllGroupAndMember -ADGroupName $ADGroupName | Where-Object {$_.objectClass -eq "user"} | Get-ADUser -Properties userAccountControl | Where-Object { $_.userAccountControl -eq $UAC }).Count
if ($count -lt $warningThreshold) {
    $outLog = @("OK: $ADGroupName group is not full", "There is $count users in the group")
    Write-Output $outLog
    exit 0
}
elseif ($count -ge $warningThreshold -and $count -lt $criticalThreshold)
{
    $outLog = @("WARNING: $ADGroupName group is almost full", "There is $count users in the group out of $criticalThreshold")
    Write-Output $outLog
    exit 1
} else
{
    $outLog = @("CRITICAL: $ADGroupName group is full", "There is $count users in the group out of $criticalThreshold")
    Write-Output $outLog
    exit 2
}