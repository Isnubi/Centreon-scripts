#==========================================================================================
#
# SCRIPT NAME        :     Check-AD-Service-Account-Password-Expiration.ps1
#
# AUTHOR             :     Louis GAMBART
# CREATION DATE      :     2023.04.10
# RELEASE            :     v2.0.0
# USAGE SYNTAX       :     .\Check-AD-Service-Account-Password-Expiration.ps1
#
# SCRIPT DESCRIPTION :     This script checks the expiration date of the password of the service in Active Directory in order to monitor them via NRPE.
#
#==========================================================================================
#                 - RELEASE NOTES -
# v1.0.0  2023.04.10 - Louis GAMBART - Initial version
# v1.0.1  2023.04.12 - Louis GAMBART - Add SearchBase parameter to search in specific OU
# v1.1.0  2023.04.12 - Louis GAMBART - Add exception list
# v1.1.1  2023.04.12 - Louis GAMBART - Add a search pattern with the name of the account
# v1.2.0  2023.04.12 - Louis GAMBART - Use of fine-grained password policy to check the expiration date
# v1.3.0  2023.04.12 - Louis GAMBART - Rework script output to be compatible with Centreon
# v1.4.0  2023.05.04 - Louis GAMBART - Fix problem with Get-ADFineGrainedPasswordPolicy permission by adding manual password expiration
# v1.4.1  2023.05.04 - Louis GAMBART - Add missing Write-Output for WARNING and OK Centreon status
# v1.5.0  2023.06.22 - Louis GAMBART - Fix error in variable type
# v1.5.1  2023.06.22 - Louis GAMBART - Fix error in the count of the number of days before expiration in output message
# v1.5.2  2023.06.22 - Louis GAMBART - Fix status message of the output (original message was the start verbose message of the script)
# v1.5.3  2023.06.22 - Louis GAMBART - Add a specific list of users to check
# v1.5.4  2023.06.22 - Louis GAMBART - Fix status message of the output
# v1.5.5  2023.07.01 - Louis GAMBART - Remove useless variable
# v1.6.0  2023.07.04 - Louis GAMBART - Remove useless variable reinitialization
# v1.6.1  2023.07.04 - Louis GAMBART - Add centreon output when AD module is not loadable
# v1.6.2  2023.07.05 - Louis GAMBART - Change output message for script error (trap and AD module check) from error to unknown
# v1.6.3  2023.07.05 - Louis GAMBART - Update try/catch to send centreon unknown status when AD module is not loadable
# v1.6.4  2023.07.05 - Louis GAMBART - Remove useless functions
# v1.7.0  2023.07.09 - Louis GAMBART - Update Centreon output
# v2.0.0  2023.07.26 - Louis GAMBART - Rework to use my new template
#
#==========================================================================================


###################
#                 #
#  I - VARIABLES  #
#                 #
###################

# clear error variable
$error.clear()

# set warning and error expiration days
[int] $daysWarningExpiration = 60
[int] $daysErrorExpiration = 30

# active directory users
[System.Collections.ArrayList] $errorServiceUsers = @()
[System.Collections.ArrayList] $warningServiceUsers = @()

# set the service user search pattern and OU
[String] $serviceUsersSearchPattern = "SVC-*"
[String] $serviceUsersOU = ""

# specific users list
[System.Collections.ArrayList] $specificServiceUsers = @()
# @("SVC-SPECIFIC1", "SVC-SPECIFIC2")
# Replace with SAmAccountName

# execption list
[System.Collections.ArrayList] $exceptionList = @()
# @("SVC-EXCEPTION1", "SVC-EXCEPTION2")
# Replace with SAmAccountName

# password policy
# [String] $passwordPolicyName = ""
# In the case that you don't have the rights to read the fine-grained password policy, you can set the password expiration in days
# In the case you can, you have to uncomment the string above and comment the line below and do the same in the function Get-Password-Expiration-FGPP
[Int32] $PasswordPolicyExpiration = 365


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


function Find-Module {
    <#
    .SYNOPSIS
    Check if a module is installed
    .DESCRIPTION
    Check if a module is installed
    .INPUTS
    System.String: The name of the module
    .OUTPUTS
    System.Boolean: True if the module is installed, false otherwise
    .EXAMPLE
    Check-Module -ModuleName 'ActiveDirectory'
    True
    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName
    )
    begin {}
    process {
        $module = Get-Module -Name $ModuleName -ListAvailable
        if ($module) {
            return $true
        } else {
            return $false
        }
    }
    end {}
}


function Get-Password-Expiration-FGPP {
    <#
    .SYNOPSIS
    Get the password expiration domain policy
    .DESCRIPTION
    Get the password expiration domain policy
    .INPUTS
    FGPPName: The name of the password policy
    .OUTPUTS
    System.Int32: The password expiration domain policy
    .EXAMPLE
    Get-Password-Expiration-FGPP
    90
    #>
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String] $FGPPName
    )
    begin {
    }
    process {
        # return (Get-ADFineGrainedPasswordPolicy -Identity $FGPPName).MaxPasswordAge.Days
        return $PasswordPolicyExpiration
    }
    end {}
}


######################
#                    #
#  III - PARAMETERS  #
#                    #
######################

if (($PasswordPolicyExpiration -ne $null) -and ($null -eq $passwordPolicyName)) {
    $passwordPolicyName = "foo"
}

# date&time parameters
[System.Int32] $maxPasswordAge = Get-Password-Expiration-FGPP -FGPPName $passwordPolicyName
[System.DateTime] $expiredDate = (Get-Datetime).addDays(-$maxPasswordAge)
[System.DateTime] $warningDate = (Get-Datetime).addDays(-($maxPasswordAge - $daysWarningExpiration -1))
[System.DateTime] $errorDate = (Get-Datetime).addDays(-($maxPasswordAge - $daysErrorExpiration -1))


########################
#                      #
#  IV - ERROR HANDLER  #
#                      #
########################

# trap errors
trap {
    $outLog = @("UNKNOWN: An error has occured and the script can't run: $_")
    Write-Output $outLog
    exit 3
}


##########################
#                        #
#  V - SCRIPT EXECUTION  #
#                        #
##########################

try { Import-Module -Name 'ActiveDirectory' }
catch {
    $outLog = @("UNKNOWN: Unable to import the ActiveDirectory module: $_")
    Write-Output $outLog
    exit 3
}

$warningServiceUsers = Get-ADUser -Filter {(PasswordLastSet -lt $warningDate) -and (PasswordLastSet -gt $errorDate) -and (PasswordNeverExpires -eq $false) -and (Enabled -eq $true) -and (Name -like $serviceUsersSearchPattern)} -Properties PasswordNeverExpires, PasswordLastSet -SearchBase $serviceUsersOU | Select-Object SamAccountName, PasswordLastSet, @{name = "DaysUntilExpired"; Expression = {$_.PasswordLastSet - $ExpiredDate | Select-Object -ExpandProperty Days}} | Sort-Object PasswordLastSet
$errorServiceUsers = Get-ADUser -Filter {(PasswordLastSet -lt $ErrorDate) -and (PasswordLastSet -gt $expiredDate) -and (PasswordNeverExpires -eq $false) -and (Enabled -eq $true) -and (Name -like $serviceUsersSearchPattern)} -Properties PasswordNeverExpires, PasswordLastSet -SearchBase $serviceUsersOU | Select-Object SamAccountName, PasswordLastSet, @{name = "DaysUntilExpired"; Expression = {$_.PasswordLastSet - $ExpiredDate | Select-Object -ExpandProperty Days}} | Sort-Object PasswordLastSet

if ($specificServiceUsers.Count -ne "0") {
    foreach ($specificUser in $specificServiceUsers) {
        $specificUser = Get-ADUser -Filter {(SamAccountName -eq $specificUser) -and (PasswordNeverExpires -eq $false) -and (Enabled -eq $true)} -Properties PasswordNeverExpires, PasswordLastSet -SearchBase $serviceUsersOU | Select-Object SamAccountName, PasswordLastSet, @{name = "DaysUntilExpired"; Expression = {$_.PasswordLastSet - $ExpiredDate | Select-Object -ExpandProperty Days}}
        if ($specificUser.PasswordLastSet -lt $warningDate -and $specificUser.PasswordLastSet -gt $errorDate) {
            $warningServiceUsers.Add($specificUser)
        } elseif ($specificUser.PasswordLastSet -lt $errorDate -and $specificUser.PasswordLastSet -gt $expiredDate) {
            $errorServiceUsers.Add($specificUser)
        }
    }
}

if ($exceptionList.Count -ne "0") {
    $warningServiceUsers = $warningServiceUsers | Where-Object { $_.SamAccountName -notin $exceptionList }
    $errorServiceUsers = $errorServiceUsers | Where-Object { $_.SamAccountName -notin $exceptionList }
}

if ($errorServiceUsers.Count -gt 0) {
    $status += "CRITICAL: $($errorServiceUsers.Count)", "users has the password expired in the last", $daysErrorExpiration, "days "
    foreach ($errorUser in $errorServiceUsers)
    {
        $outLog += "\n $( $errorUser.SamAccountName ) ($( $errorUser.DaysUntilExpired ) days) "
    }
    $outLog += "\n\n WARNINGS \n(from $daysErrorExpiration to $daysWarningExpiration days):\n\n"
    foreach ($warningUser in $warningServiceUsers)
    {
        $outLog += "\n $( $warningUser.SamAccountName ) ($( $warningUser.DaysUntilExpired ) days) "
    }
    $outLog = @($status, $outLog)
    Write-Output $outLog
    exit 2
}
elseif ($warningServiceUsers.Count -gt 0) {
    $status += "WARNING: $($warningServiceUsers.Count)", "users has the password expiring in the next", $daysWarningExpiration, "days "
    foreach ($warningUser in $warningServiceUsers)
    {
        $outLog += "\n $( $warningUser.SamAccountName ) ($( $warningUser.DaysUntilExpired ) days) "
    }
    $outLog = @($status, $outLog)
    Write-Output $outLog
    exit 1
}
else {
    $outLog = @("OK: No user has the password expiring", "No user has the password expiring in the next", $daysWarningExpiration, "days")
    Write-Output $outLog
    exit 0
}