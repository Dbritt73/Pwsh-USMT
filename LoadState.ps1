<#
.Synopsis
   Migrate Windows User profile from one system setup to another.
.DESCRIPTION
   Utilizes the User State Migration Tool (USMT), provided through the Windows Assesment and Deployment Kit (Windows ADK).
   Loads previously migrated user data to a new system.
.EXAMPLE
  LoadState.ps1 -ComputerName SERVER1 -Verbose
.EXAMPLE
  LoadState.ps1 -Computername SERVER1 -Arch 'x86' -Verbose
#>

[CmdletBinding()]
Param (
  [Parameter(HelpMessage="Location of saved user state, can be local or network share")]
  [string]$MigSource = '\\Server\USMTshare',

  [Parameter( Mandatory=$true,
              HelpMessage="Name of the computer that has been migrated and want to extract user state from")]
  [string]$ComputerName,

  [Parameter(HelpMessage="Architecture of new system - x86 or x64")]
  [ValidateSet("x64", "x86")]
  [string]$Arch = 'x64'
)

Begin {}

Process {

  Try {

    $ScriptPath = $MyInvocation.MyCommand.Path
    $CurrentDir = Split-Path -Path $ScriptPath
    Write-Verbose -Message "Working directory as $CurrentDir"

    Write-Verbose -Message "Map $MigSource to extract user migration file"
    #New-PSDrive -Name 'M' -PSProvider 'FileSystem' -Root $MigSource -Persist -Credential (Get-Credential)

    #Migrate printers
    Write-verbose "Importing installed printers from $MigSource\Stores\$ComputerName"
    Start-Process -FilePath "$env:windir\System32\spool\tools\PrintBrm.exe" -ArgumentList "-R -F $MigSource\Stores\$ComputerName\$ComputerName.PrinterExport" -NoNewWindow -Wait
    Write-Verbose "Printer Import complete"

    #NOTE the backticks as line breaks for readability, operates as single line.
    Write-Verbose -Message "Executing LoadState on new system from migration of $ComputerName"
    &$CurrentDir\$Arch\loadstate.exe `
    $MigSource\Stores\$ComputerName `
    /i:$CurrentDir\$Arch\MigUser.xml `
    /i:$CurrentDir\$Arch\migapp.xml `
    /i:$CurrentDir\$Arch\MigDocs.xml `
    /l:$MigSource\Stores\$ComputerName\Loadstate.log `
    /UE:$ComputerName\ATUS `
    /v:13 `
    /lac `
    /c

    Write-Verbose -Message "LoadState complete"

    #Export printers for migration
    #PrinterBRM.exe -R -F $MigSource\Stores\$ComputerName\$ComputerName.PrinterExport
  
  } Catch {
  
    Write-Warning "$ComputerName - $($Error[0].exception) -- Please see log located at $MigSource\Stores\$ComputerName\Loadstate.log for more information"
  
  }

}

End {}

