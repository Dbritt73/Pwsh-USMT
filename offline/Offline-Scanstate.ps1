
[CmdletBinding()]
Param (

    [String]$MigSource = '\\Server\USMTshare',

    [String]$ComputerName,

    [String]$NewStore = "\\Server\USMTshare\$ComputerName",

    [String]$DriveLetter

)

$ScriptPath = $MyInvocation.MyCommand.Path
$CurrentDir = Split-Path -Path $ScriptPath



&$CurrentDir\x64\scanstate.exe `
$NewStore `
/uel:30 `
/offlineWinDir:$DriveLetter\Windows `
/i:$CurrentDir\x64\MigUser.xml `
/i:$CurrentDir\x64\MigDocs.xml `
/i:$currentdir\x64\migapp.xml `
/i:$CurrentDir\ExcludeDrive.xml `
/l:$MigSource\Stores\$ComputerName\Scanstate.log `
/progress:$MigSource\Stores\$COMPUTERNAME\Progress.log `
/v:13 `
/localonly

#/i:$CurrentDir\Include.xml
