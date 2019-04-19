<#
.Synopsis
   Migrate Windows User profile from one system setup to another.
.DESCRIPTION
   Utilizes the User State Migration Tool (USMT), provided through the Windows Assesment and Deployment Kit (Windows ADK).
   Scans existing system and migrating user profile information including files, and application settings to another location.
   Ability to specifcy multiple active users over last # days, or a single user determined by username. Script supports
   both x86 and x64 architectures.
.Parameter MigSource
   Location to save user state, can be local or network share
.Parameter User
   Specify Username of user to be migrated
.Parameter Arch
   Architecure of the system being run on - x64 or x86
.Parameter Days
   Number of days to go back and migrate profiles that have been logged into during that timespan. Default is 30 days
.EXAMPLE
  ScanState.ps1 -SingleUser -User 'username' -Verbose
.EXAMPLE
  Scanstate.ps1 -Days '90' -Arch 'x86' -migsource '\\Folderpath\Store' -Verbose
#>

[CmdletBinding()]
Param (

    [string]$MigSource = '\\Server\USMTshare',

    [Parameter(ParameterSetName = 'Single')]
    [string]$user,

    [ValidateSet('x64', 'x86')]
    [string]$Arch = 'x64',

    [Parameter(ParameterSetName = 'Multi')]
    [int]$Days = 30
)

Begin {

    $ScriptPath = $MyInvocation.MyCommand.Path
    $CurrentDir = Split-Path -Path $ScriptPath
    Write-Verbose -Message "Working directory as $CurrentDir"

}

Process {

    Try {

        Write-Verbose -Message "Creating migration store for $ENV:COMPUTERNAME at $MigSource"
        $NewStore = "$MigSource\Stores\$ENV:COMPUTERNAME"

        New-Item -Path $NewStore -ItemType Directory

        #Migrate printers
        Write-verbose "Exporting installed printers from $ENV:COMPUTERNAME to PrinterExport file at $newstore"
        $ArgumentList = @(

            "-B"
            "-F"
            "$newstore\$ENV:COMPUTERNAME.PrinterExport"

        )

        Start-Process "$env:windir\System32\spool\tools\PrintBrm.exe" -ArgumentList $ArgumentList -Wait -NoNewWindow
        Write-Verbose "Printer export complete"

        #Single User
        if ($PSBoundParameters.ContainsKey('User')) {

            Write-Verbose -Message "Migrating $User from $ENV:COMPUTERNAME"
            $ArgumentList = @(

                "$NewStore"
                "/i:$CurrentDir\$Arch\MigUser.xml"
                "/i:$CurrentDir\$Arch\MigDocs.xml"
                "/i:$currentdir\$Arch\migapp.xml"
                "/l:$NewStore\Scanstate.log"
                "/progress:$NewStore\Progress.log"
                "/v:13"
                "/ue:*\*"
                "/ui:DOMAIN\$user"
                "/localonly"
                "/C"
                "/EFS:COPYRAW"

            )

            Start-Process "$CurrentDir\$Arch\scanstate.exe" -ArgumentList $ArgumentList -Wait -NoNewWindow

        #Multi-user
        } Else {

            Write-Verbose -Message "Migrating all active user profiles from last $Days days"
            $ArgumentList = @(

                "$NewStore"
                "/uel:$Days"
                "/i:$CurrentDir\$Arch\MigUser.xml"
                "/i:$CurrentDir\$Arch\MigDocs.xml"
                "/i:$currentdir\$Arch\migapp.xml"
                "/l:$NewStore\Scanstate.log"
                "/progress:$NewStore\Progress.log"
                "/v:13"
                "/localonly"
                "/C"
                "/EFS:COPYRAW"

            )

            Start-Process "$CurrentDir\$Arch\scanstate.exe" -ArgumentList $ArgumentList -Wait -NoNewWindow

        }

    } Catch {

        # get error record
        [Management.Automation.ErrorRecord]$e = $_

        # retrieve information about runtime error
        $info = [PSCustomObject]@{

            Exception = $e.Exception.Message
            Reason    = $e.CategoryInfo.Reason
            Target    = $e.CategoryInfo.TargetName
            Script    = $e.InvocationInfo.ScriptName
            Line      = $e.InvocationInfo.ScriptLineNumber
            Column    = $e.InvocationInfo.OffsetInLine

        }

        # output information. Post-process collected info, and log info (optional)
        Write-Output -InputObject $info

    }

}

End {}
