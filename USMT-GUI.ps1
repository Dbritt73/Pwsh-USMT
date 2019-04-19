Add-Type -AssemblyName PresentationFramework

Function Invoke-USMTScanState {
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

        [Parameter( Mandatory=$true,
                    HelpMessage='Location to save user state, can be local or network share')]
        [string]$MigSource,

        [Parameter(ParameterSetName = 'Single')]
        [string]$user,

        [Parameter( Mandatory=$true,
                    HelpMessage='Architecure of the system being run on')]
        [ValidateSet('x64', 'x86')]
        [string]$Arch,

        [Parameter(ParameterSetName = 'Multi')]
        [int]$Days = 30

    )

    Begin {}

    Process {

        Try {

            $NewStore = ('{0}\Stores\{1}' -f $MigSource, $ENV:COMPUTERNAME)
            New-Item -Path $NewStore -ItemType Directory
            $USMTDir = $(Split-path -Path $PSCommandPath -Parent)

            if ($PSBoundParameters.ContainsKey('User')) {

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

                Start-Process "$USMTDir\$Arch\scanstate.exe" -ArgumentList $ArgumentList -Wait -NoNewWindow

            } Else {

                #Multi-user
                $ArgumentList = @(

                    "$NewStore"
                    "/uel:$Days"
                    "/i:$USMTDir\$Arch\MigUser.xml"
                    "/i:$USMTDir\$Arch\MigDocs.xml"
                    "/i:$USMTDir\$Arch\migapp.xml"
                    "/l:$NewStore\Scanstate.log"
                    "/progress:$NewStore\Progress.log"
                    "/v:13"
                    "/localonly"
                    "/C"
                    "/EFS:COPYRAW"

                )

                Start-Process "$USMTDir\$Arch\scanstate.exe" -ArgumentList $ArgumentList -Wait -NoNewWindow

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

}

Function Invoke-USMTLoadState {
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

        [Parameter( Mandatory = $true,
                    HelpMessage = 'Location of saved user state, can be local or network share')]
        [string]$MigSource,

        [Parameter( Mandatory = $true,
                    HelpMessage = 'Name of the computer that has been migrated and want to extract user state from')]
        [string]$ComputerName,


        [ValidateSet('x64', 'x86')]
        [string]$Arch = 'x64'

    )

    Begin {}

    Process {

        Try {

            #NOTE the backticks as line breaks for readability, operates as single line.
            $USMTDir = $(Split-path -Path $PSCommandPath -Parent)

            $ArgumentList = @(

                "$MigSource\Stores\$ComputerName"
                "/i:$USMTDir\$Arch\MigUser.xml"
                "/i:$USMTDir\$Arch\migapp.xml"
                "/i:$USMTDir\$Arch\MigDocs.xml"
                "/l:$MigSource\Stores\$ComputerName\Loadstate.log"
                "/UE:$ComputerName\LOCAL_USER"
                "/v:13"
                "/lac"
                "/c"
            )

            Start-Process "$USMTDir\$Arch\loadstate.exe" -ArgumentList $ArgumentList -Wait -NoNewWindow

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

}

Function Invoke-PrinterMigration {
  <#
      .SYNOPSIS
      Describe purpose of "Invoke-PrinterMigration" in 1-2 sentences.

      .DESCRIPTION
      Add a more complete description of what the function does.

      .PARAMETER MigSource
      Describe parameter -MigSource.

      .PARAMETER ComputerName
      Describe parameter -ComputerName.

      .PARAMETER Intent
      Describe parameter -Intent.

      .EXAMPLE
      Invoke-PrinterMigration -MigSource Value -ComputerName Value -Intent Value
      Describe what this call does

      .NOTES
      Place additional notes here.

      .LINK
      URLs to related sites
      The first link is opened by Get-Help -Online Invoke-PrinterMigration

      .INPUTS
      List of input types that are accepted by this function.

      .OUTPUTS
      List of output types produced by this function.
  #>


    [CmdletBinding()]
    Param (

        [Parameter( Mandatory=$true,
                    HelpMessage='Add help message for user')]
        [string]$MigSource,

        [Parameter( Mandatory=$true,
                    HelpMessage='Add help message for user')]
        [string]$ComputerName,

        [Parameter( Mandatory=$true,
                    HelpMessage='Add help message for user')]
        [ValidateSet('Export', 'Import')]
        [string]$Intent

    )

    Begin {}

    Process {

        Switch ($Intent) {

            'Export' {

                $NewStore = ('{0}\Stores\{1}' -f $MigSource, $ENV:COMPUTERNAME)
                $ArgumentList = @(

                    "-B"
                    "-F"
                    "$newstore\$ENV:COMPUTERNAME.PrinterExport"

                )

                Start-Process "$env:windir\System32\spool\tools\PrintBrm.exe" -ArgumentList $ArgumentList -Wait -NoNewWindow

            }

            'Import' {

                $ArgumentList = @(

                    "-R"
                    "-F"
                    "$MigSource\Stores\$ComputerName\$ComputerName.PrinterExport"

                )

                Start-Process "$env:windir\System32\spool\tools\PrintBrm.exe" -ArgumentList $ArgumentList -Wait -NoNewWindow

            }

        }

    }

    End {}

}

#XAML data for WPF
[XML]$Form = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="User State Migration Tool" Height="434.727" Width="567.922">
    <Grid>
        <TabControl HorizontalAlignment="Left" Height="399" Margin="10,10,0,0" VerticalAlignment="Top" Width="772">
            <TabItem Header="Backup" Margin="-2,-2,-78,0">
                <Grid Background="#FFE5E5E5" Margin="0,0,-2,-3" RenderTransformOrigin="0.5,0.5">
                    <Grid.RenderTransform>
                        <TransformGroup>
                            <ScaleTransform/>
                            <SkewTransform/>
                            <RotateTransform Angle="-0.084"/>
                            <TranslateTransform/>
                        </TransformGroup>
                    </Grid.RenderTransform>
                    <Label Content="Server: " HorizontalAlignment="Left" Height="27" Margin="14,18,0,0" VerticalAlignment="Top" Width="78"/>
                    <TextBox Name="Destination" HorizontalAlignment="Left" Height="20" Margin="62,22,0,0" TextWrapping="Wrap" Text="\\SERVER\SHARE" VerticalAlignment="Top" Width="274"/>
                    <Image HorizontalAlignment="Left" Height="85" Margin="387,13,0,0" VerticalAlignment="Top" Width="152" Source="$PSscriptroot\PowerShell_5.0_icon.png"/>
                    <Label Content="System Architecture (x86 or x64):" HorizontalAlignment="Left" Height="24" Margin="14,77,0,0" VerticalAlignment="Top" Width="185"/>
                    <CheckBox Name="Scanx64check" Content="x64" HorizontalAlignment="Left" Height="14" Margin="212,84,0,0" VerticalAlignment="Top" Width="45"/>
                    <CheckBox Name="Scanx86Check" Content="x86" HorizontalAlignment="Left" Margin="280,84,0,0" VerticalAlignment="Top"/>
                    <CheckBox Name="ExportPrintersCheck" Content="Export Printers?" HorizontalAlignment="Left" Height="20" Margin="14,126,0,0" VerticalAlignment="Top" Width="120"/>
                    <CheckBox Name="SingleUserCheck" Content="Single User?" HorizontalAlignment="Left" Margin="14,166,0,0" VerticalAlignment="Top"/>
                    <CheckBox Name="MultiUserCheck" Content="Multi-User?" HorizontalAlignment="Left" Margin="14,206,0,0" VerticalAlignment="Top"/>
                    <Label Content="Username: " HorizontalAlignment="Left" Height="29" Margin="130,160,0,0" VerticalAlignment="Top" Width="113"/>
                    <TextBox Name="Username" HorizontalAlignment="Left" Height="19" Margin="199,166,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="149"/>
                    <Label Content="Number of Days: " HorizontalAlignment="Left" Margin="130,200,0,0" VerticalAlignment="Top"/>
                    <TextBox Name="Days" HorizontalAlignment="Left" Height="22" Margin="243,204,0,0" TextWrapping="Wrap" Text="30" VerticalAlignment="Top" Width="32"/>
                    <Button Name="StartScanState" Content="Start ScanState" HorizontalAlignment="Left" Height="91" Margin="154,267,0,0" VerticalAlignment="Top" Width="240"/>
                </Grid>
            </TabItem>
            <TabItem Header="Restore" Margin="78,-3,-158,1">
                <Grid Background="#FFE5E5E5" Margin="0,0,218,0">
                    <Label Content="Server: " HorizontalAlignment="Left" Height="23" Margin="15,18,0,0" VerticalAlignment="Top" Width="51" Grid.ColumnSpan="2"/>
                    <TextBox Name="LoadSource" HorizontalAlignment="Left" Height="17" Margin="61,29,0,0" TextWrapping="Wrap" Text="\\SERVER\SHARE" VerticalAlignment="Top" Width="255"/>
                    <Label Content="Old ComputerName: " HorizontalAlignment="Left" Height="27" Margin="15,72,0,0" VerticalAlignment="Top" Width="122"/>
                    <TextBox Name="ComputerName" HorizontalAlignment="Left" Height="21" Margin="142,76,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="178"/>
                    <Label Content="System Architecture (x86 or x64):" HorizontalAlignment="Left" Height="25" Margin="15,126,0,0" VerticalAlignment="Top" Width="187"/>
                    <CheckBox Name="LoadX64Check" Content="x64" HorizontalAlignment="Left" Height="16" Margin="207,131,0,0" VerticalAlignment="Top" Width="44"/>
                    <CheckBox Name="Loadx86Check" Content="x86" HorizontalAlignment="Left" Height="16" Margin="278,131,0,0" VerticalAlignment="Top" Width="46"/>
                    <CheckBox Name="RestorePrintersCheck" Content="Restore Printers?" HorizontalAlignment="Left" Height="18" Margin="15,177,0,0" VerticalAlignment="Top" Width="158"/>
                    <Button Name="StartLoadstate" Content="Start Loadstate" HorizontalAlignment="Left" Height="88" Margin="97,244,0,0" VerticalAlignment="Top" Width="308"/>
                    <Image HorizontalAlignment="Left" Height="85" Margin="387,13,0,0" VerticalAlignment="Top" Width="152" Source="$PSscriptRoot\PowerShell_5.0_icon.png"/>
                </Grid>
            </TabItem>
        </TabControl>
    </Grid>
</Window>
"@

$NR=(New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $Form)
$Win=[Windows.Markup.XamlReader]::Load( $NR )

#ScanState controls
$Server = $win.FindName('Destination')
$Scanx64 = $win.FindName('Scanx64check')
$Scanx86 = $win.FindName('Scanx86Check')
$ExportPrinters = $win.FindName('ExportPrintersCheck')
$SingleUser = $win.FindName('SingleUserCheck')
$MultiUser = $win.FindName('MultiUserCheck')
$Username = $win.FindName('Username')
$NumberofDays = $win.FindName('Days')
$StartScan = $win.FindName('StartScanState')

#LoadState Controls
$ComputerName = $win.FindName('ComputerName')
$MigSource = $win.FindName('LoadSource')
$Loadx64 = $win.FindName('LoadX64Check')
$Loadx86 = $win.FindName('LoadX86Check')
$ImportPrinters = $win.FindName('RestorePrinterCheck')
$StartLoad = $win.FindName('StartLoadstate')

$StartScan.add_click({

    if ($ExportPrinters.ischecked) {

        Invoke-PrinterMigration -MigSource $Server.Text -Intent 'Export'

    } Else {}

    if ($SingleUser.ischecked -and $Scanx64.ischecked) {

        Invoke-USMTScanState -MigSource $Server.text -user $Username.text -Arch 'x64'

    } elseif ($SingleUser.ischecked -and $Scanx86.ischecked) {

        Invoke-USMTScanState -MigSource $Server.text -user $Username.text -Arch 'x86'

    } elseif ($MultiUser.ischecked -and $Scanx64.ischecked) {

        Invoke-USMTScanState -MigSource $Server.text -Arch 'x64' -Days $NumberofDays.Text

    } elseif ($MultiUser.ischecked -and $Scanx86.ischecked) {

        Invoke-USMTScanState -MigSource $Server.text -Arch 'x86' -Days $NumberofDays.Text

    } Else {

        Return

    }

})

$StartLoad.add_click({

    if ($ImportPrinters.ischecked) {

        Invoke-PrinterMigration -MigSource $MigSource.Text -Intent 'Import'

    }

    if ($Loadx64.ischecked) {

        Invoke-USMTLoadState -MigSource $MigSource.Text -ComputerName $ComputerName.Text -Arch 'x64'

    } elseif ($Loadx86.ischecked) {

        Invoke-USMTLoadState -MigSource $MigSource.Text -ComputerName $ComputerName.Text -Arch 'x86'

    } Else {}

})

$Win.ShowDialog()