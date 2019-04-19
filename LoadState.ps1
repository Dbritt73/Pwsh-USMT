<#
.Synopsis
   Migrate Windows User profile from one system setup to another.
.DESCRIPTION
   Utilizes the User State Migration Tool (USMT), provided through the Windows Assesment and Deployment Kit (Windows ADK).
   Loads previously migrated user data to a new system.
.Parameter MigSource
   Location of saved user state, can be local or network share
.Parameter ComputerName
   Name of the computer that has been migrated and want to extract user state from
.Parameter Arch
   Architecure of the system being run on - x64 or x86
.EXAMPLE
  LoadState.ps1 -ComputerName SERVER1 -Verbose
.EXAMPLE
  LoadState.ps1 -Computername SERVER1 -Arch 'x86' -Verbose
#>

[CmdletBinding()]
Param (

    [string]$MigSource = '\\Server\USMTshare',

    [Parameter( Mandatory=$true,
                HelpMessage="Name of the computer that has been migrated and want to extract user state from")]
    [string]$ComputerName,

    [ValidateSet("x64", "x86")]
    [string]$Arch = 'x64'

)

Begin {}

Process {

    Try {

        $ScriptPath = $MyInvocation.MyCommand.Path
        $CurrentDir = Split-Path -Path $ScriptPath
        Write-Verbose -Message "Working directory as $CurrentDir"

        #Migrate printers
        Write-verbose "Importing installed printers from $MigSource\Stores\$ComputerName"
        $ArgumentList = @(

            "-R"
            "-F"
            "$MigSource\Stores\$ComputerName\$ComputerName.PrinterExport"

        )
        Write-Verbose "Printer Import complete"

        Write-Verbose -Message "Executing LoadState on new system from migration of $ComputerName"
        $ArgumentList = @(

            "$MigSource\Stores\$ComputerName"
            "/i:$CurrentDir\$Arch\MigUser.xml"
            "/i:$CurrentDir\$Arch\migapp.xml"
            "/i:$CurrentDir\$Arch\MigDocs.xml"
            "/l:$MigSource\Stores\$ComputerName\Loadstate.log"
            "/UE:$ComputerName\Local_Account"
            "/v:13"
            "/lac"
            "/c"

        )

        Start-Process "$CurrentDir\$Arch\loadstate.exe" -ArgumentList $ArgumentList -Wait -NoNewWindow

        Write-Verbose -Message "LoadState complete"

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

