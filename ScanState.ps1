<#
.Synopsis
   Migrate Windows User profile from one system setup to another.
.DESCRIPTION
   Utilizes the User State Migration Tool (USMT), provided through the Windows Assesment and Deployment Kit (Windows ADK).
   Scans existing system and migrating user profile information including files, and application settings to another location.
   Ability to specifcy multiple active users over last # days, or a single user determined by username. Script supports
   both x86 and x64 architectures. 
.EXAMPLE
  ScanState.ps1 -SingleUser -User 'username' -Verbose
.EXAMPLE
   Scanstate.ps1 -Days '90' -Arch 'x86' -migsource '\\Folderpath\Store' -Verbose
#>

[CmdletBinding()]
Param (
    [Parameter(HelpMessage="Location to save user state, can be local or network share")]
    [string]$MigSource = '\\Server\USMTshare',

    [Parameter(HelpMessage="Specify UserName of user to be migrated")]
    [string]$user,

    [Parameter(HelpMessage="Architecure of the system being run on")]
    [ValidateSet('x64', 'x86')]
    [string]$Arch = 'x64',

    [int]$Days = 30
)

Begin {}

Process {

    Try {

        $ScriptPath = $MyInvocation.MyCommand.Path
        $CurrentDir = Split-Path -Path $ScriptPath
        Write-Verbose -Message "Working directory as $CurrentDir"
        
        Write-Verbose -Message "Creating migration store for $ENV:COMPUTERNAME at $MigSource"
        #New-PSDrive -Name 'M' -PSProvider 'FileSystem' -Root $MigSource -Persist -Credential (Get-Credential)
        $NewStore = "$MigSource\Stores\$ENV:COMPUTERNAME"
        New-Item -Path $NewStore -ItemType Directory

        #Migrate printers
        Write-verbose "Exporting installed printers from $ENV:COMPUTERNAME to PrinterExport file at $newstore"
        Start-Process -FilePath "$env:windir\System32\spool\tools\PrintBrm.exe" -ArgumentList "-B -F $newstore\$ENV:COMPUTERNAME.PrinterExport" -NoNewWindow -Wait
        Write-Verbose "Printer export complete"
        
        #USMT ScanState
        #Single User
        if ($PSBoundParameters.ContainsKey('User')) {
        
            Write-Verbose -Message "Migrating $User from $ENV:COMPUTERNAME"
            &$CurrentDir\$Arch\scanstate.exe `
            $NewStore `
            /i:$CurrentDir\$Arch\MigUser.xml `
            /i:$CurrentDir\$Arch\MigDocs.xml `
            /i:$currentdir\$Arch\migapp.xml `
            /l:$NewStore\Scanstate.log `
            /progress:$NewStore\Progress.log `
            /v:13 `
            /ue:*\* `
            /ui:WWU\$user `
            /localonly `
            /C
        #Multi-user
        } Else {
        
            Write-Verbose -Message "Migrating all active user profiles from last $Days days"
            &$CurrentDir\$Arch\scanstate.exe `
            $NewStore `
            /uel:$Days `
            /i:$CurrentDir\$Arch\MigUser.xml `
            /i:$CurrentDir\$Arch\MigDocs.xml `
            /i:$currentdir\$Arch\migapp.xml `
            /l:$NewStore\Scanstate.log `
            /progress:$NewStore\Progress.log `
            /v:13 `
            /localonly `
            /C
        }
        
    } Catch {
            
        Write-Warning "$ComputerName - $($Error[0])"
        
    }  

}

End {}
