#.ExternalHelp PoshProgressBar.psm1-help.xml
Function New-ProgressBar {
    [CmdletBinding()]
    param(

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'MaterialDesign')]
        [String]$IconPath,

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'MaterialDesign')]
        [Bool]$IsIndeterminate = $True,

        [Parameter(ParameterSetName = 'MaterialDesign', Mandatory = $true)]
        [switch]$MaterialDesign,

        [Parameter(ParameterSetName = 'MaterialDesign')]
        [ValidateSet("Circle", "Horizontal", "Vertical")]
        [String]$Type = "Horizontal",

        [Parameter(ParameterSetName = 'MaterialDesign')]
        [ValidateSet("Red", "Pink", "Purple", "DeepPurple", "Indigo",
            "Blue", "LightBlue", "Cyan", "Teal", "Green", "LightGreen",
            "Lime", "Yellow", "Amber", "Orange", "DeepOrange", "Brown",
            "Grey", "BlueGrey")]
        [String]$PrimaryColor = "Blue",

        [Parameter(ParameterSetName = 'MaterialDesign')]
        [ValidateSet("Red", "Pink", "Purple", "DeepPurple", "Indigo",
            "Blue", "LightBlue", "Cyan", "Teal", "Green", "LightGreen",
            "Lime", "Yellow", "Amber", "Orange", "DeepOrange")]
        [String]$AccentColor = "LightBlue",

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'MaterialDesign')]
        [ValidateSet("Large", "Medium", "Small")]
        [String]$Size = "Medium",

        [Parameter(ParameterSetName = 'MaterialDesign')]
        [ValidateSet("Dark", "Light")]
        [String]$Theme = "Light",

        # Contributed via issue #17 triage (VDL / Paul Vergouwe): window chrome options.
        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'MaterialDesign')]
        [Bool]$Topmost = $True,

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'MaterialDesign')]
        [ValidateSet("NoResize", "CanMinimize", "CanResize", "CanResizeWithGrip")]
        [String]$ResizeMode = "NoResize",

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'MaterialDesign')]
        [Bool]$ShowInTaskbar = $True,

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'MaterialDesign')]
        [String]$PicturePath = "",

        [Parameter(ParameterSetName = 'Standard')]
        [Parameter(ParameterSetName = 'MaterialDesign')]
        [Switch]$ShowOnPrimaryMonitor = $False
    )

    if (-not ([System.Management.Automation.PSTypeName]'System.Windows.Window').Type) {
        # Friendly error on non-Windows / no-WPF hosts instead of cryptic XAML failures.
        if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
            throw "New-ProgressBar requires Windows PowerShell 5.1 / Windows PowerShell with WPF (presentationframework). This platform is not supported."
        }
    }

    # Validate optional file inputs early so typos fail fast instead of rendering broken XAML.
    if ($IconPath -and -not (Test-Path -Path $IconPath -PathType Leaf)) {
        Write-Warning "New-ProgressBar: IconPath '$IconPath' not found. Continuing without a custom icon."
        $IconPath = $null
    }
    if ($PicturePath -and -not (Test-Path -Path $PicturePath -PathType Leaf)) {
        Write-Warning "New-ProgressBar: PicturePath '$PicturePath' not found. Continuing without a picture."
        $PicturePath = ""
    }

    $ProgressSize = 0
    if ($PicturePath) { $ProgressSize = 100 }
    $ProgressSize = @{"Small" = $ProgressSize + 140; "Medium" = $ProgressSize + 280; "Large" = $ProgressSize + 560 }

    # Modern assembly loading (LoadWithPartialName is obsolete). Fall back silently for PS 2.0-era hosts.
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Add-Type -AssemblyName PresentationFramework -ErrorAction Stop
    }
    catch {
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
        [System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
    }

    # Issue #17 triage: on multi-monitor systems the window could open on the
    # monitor holding the mouse cursor. Opt-in relocation to the primary monitor.
    if ($ShowOnPrimaryMonitor -eq $true) {
        $POSITION = [Windows.Forms.Cursor]::Position
        $POSITION.x = 0
        $POSITION.y = 0
        [Windows.Forms.Cursor]::Position = $POSITION
    }

    $syncHash = [hashtable]::Synchronized(@{ })
    $newRunspace = [runspacefactory]::CreateRunspace()
    $syncHash.Runspace = $newRunspace
    $syncHash.Closing = $False
    $syncHash.SecondsRemainingInput = $Null
    $syncHash.StatusInput = ''
    $syncHash.CurrentOperationInput = ''
    $syncHash.IconPath = $IconPath
    $syncHash.XAML = @"
        <Window
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Name="Window" Title="Progress..." WindowStartupLocation = "CenterScreen"
            Topmost="$Topmost" ResizeMode="$ResizeMode"
            Width = "$($ProgressSize[$Size]+75)" SizeToContent = "Height" ShowInTaskbar = "$ShowInTaskbar"

            $(if($MaterialDesign){
            @'
            TextElement.Foreground="{DynamicResource MaterialDesignBody}"
        Background="{DynamicResource MaterialDesignPaper}"
        TextElement.FontWeight="Medium"
        TextElement.FontSize="14"
        FontFamily="pack://application:,,,/MaterialDesignThemes.Wpf;component/Resources/Roboto/#Roboto"
'@

            })

            $(
            if($SyncHash.IconPath){

                @"
                Icon="$($SyncHash.IconPath)"
"@

}
            )

            >
            $(

                if($MaterialDesign)
                {

                  @"
                    <Window.Resources>
                        <ResourceDictionary>
                            <ResourceDictionary.MergedDictionaries>
                                <ResourceDictionary Source="pack://application:,,,/MaterialDesignThemes.Wpf;component/Themes/MaterialDesignTheme.$Theme.xaml" />
                                <ResourceDictionary Source="pack://application:,,,/MaterialDesignThemes.Wpf;component/Themes/MaterialDesignTheme.Defaults.xaml" />
                                <ResourceDictionary Source="pack://application:,,,/MaterialDesignColors;component/Themes/Recommended/Primary/MaterialDesignColor.$PrimaryColor.xaml" />
                                <ResourceDictionary Source="pack://application:,,,/MaterialDesignColors;component/Themes/Recommended/Accent/MaterialDesignColor.$AccentColor.xaml" />
                            </ResourceDictionary.MergedDictionaries>
                        </ResourceDictionary>
                    </Window.Resources>
"@

                }

            )
            <StackPanel Margin="20">
            <Grid>
            $(
            if ($PicturePath){

                @"
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Image
                        Source="$PicturePath"
                        Width="100"
                        Height="100"
                        Stretch="Uniform"
                        Margin="0,0,10,0"
                        Grid.Row="0"
                        Grid.Column="0"
                    />
"@

                }
            )
            $(

                if($MaterialDesign)
                {

                    @"
                    <ProgressBar $(

                                    switch($Type) {

                                        "Circle" {

                                        @"
                                        Style="{StaticResource MaterialDesignCircularProgressBar}" Height="$($ProgressSize[$Size]+10)" Width="$($ProgressSize[$Size])"
"@
                                        }

                                        "Horizontal" {

                                        @"
                                        Orientation="Horizontal" Width="$($ProgressSize[$Size])"
"@

                                        }

                                        "Vertical" {

                                        @"
                                        Orientation="Vertical" Height="$($ProgressSize[$Size])"
"@

                                        }

                                    }

                                    ) IsIndeterminate="$($IsIndeterminate)"  Name="ProgressBar" />
"@

                }
                else
                {

                    @"
                    <ProgressBar IsIndeterminate="$($IsIndeterminate)" Width="$($ProgressSize[$Size])" Name="ProgressBar" />
"@

                }

            )
            </Grid>

               <TextBlock Name="PercentCompleteTextBlock" Visibility="Hidden" StackPanel.ZIndex = "99" Text="{Binding ElementName=ProgressBar, Path=Value, StringFormat={}{0:0}%}" HorizontalAlignment="Center" VerticalAlignment="Center" />
               <TextBlock Name="Status" Text="" HorizontalAlignment="Left" />
               <TextBlock Name="TimeRemaining" Text="" HorizontalAlignment="Left" />
               <TextBlock Name="CurrentOperation" Text="" HorizontalAlignment="Left" />
            </StackPanel>
        </Window>
"@

    $newRunspace.ApartmentState = "STA"
    $newRunspace.ThreadOptions = "ReuseThread"
    $newRunspace.Open() | Out-Null
    $newRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)



    $PowerShellCommand = [PowerShell]::Create().AddScript( {


            $syncHash.Window = [Windows.Markup.XamlReader]::parse( $SyncHash.XAML )
            #===========================================================================
            # Store Form Objects In PowerShell
            #===========================================================================
            ([xml]$SyncHash.XAML).SelectNodes("//*[@Name]") | ForEach-Object { $SyncHash."$($_.Name)" = $SyncHash.Window.FindName($_.Name) }
            $TimeRemaining = [System.TimeSpan]

            $updateBlock = {
                if ($SyncHash.ProgressBar.IsIndeterminate) {
                    $SyncHash.PercentCompleteTextBlock.Visibility = [System.Windows.Visibility]::Hidden
                }
                else {
                    $SyncHash.PercentCompleteTextBlock.Visibility = [System.Windows.Visibility]::Visible
                }


                if ($SyncHash.Closing -eq $True) {

                    $SyncHash.NotifyIcon.Visible = $false
                    $syncHash.Window.Close()
                    [System.Windows.Forms.Application]::Exit()
                    Break
                }


                $SyncHash.Window.Title = $SyncHash.Activity
                $SyncHash.ProgressBar.Value = $SyncHash.PercentComplete
                if ([string]::IsNullOrEmpty($SyncHash.PercentComplete) -ne $True -and $SyncHash.ProgressBar.IsIndeterminate -eq $True) {

                    $SyncHash.ProgressBar.IsIndeterminate = $False

                }
                $SyncHash.Status.Text = $SyncHash.StatusInput
                if ($SyncHash.SecondsRemainingInput) {
                    $TimeRemaining = [System.TimeSpan]::FromSeconds($SyncHash.SecondsRemainingInput)
                    $SyncHash.TimeRemaining.Text = '{0:00}:{1:00}:{2:00}' -f $TimeRemaining.Hours, $TimeRemaining.Minutes, $TimeRemaining.Seconds
                }
                $SyncHash.CurrentOperation.Text = $SyncHash.CurrentOperationInput

                $SyncHash.NotifyIcon.text = "Activity: $($SyncHash.Activity)`nPercent Complete: $($SyncHash.PercentComplete)"

            }

            ############### New Blog ##############
            $syncHash.Window.Add_SourceInitialized( {
                    ## Before the window's even displayed ...
                    ## We'll create a timer
                    $timer = New-Object System.Windows.Threading.DispatcherTimer
                    ## Which will fire 4 times every second
                    $timer.Interval = [TimeSpan]"0:0:0.25"
                    ## And will invoke the $updateBlock
                    $timer.Add_Tick( $updateBlock )
                    ## Now start the timer running
                    $timer.Start()
                    if ( $timer.IsEnabled ) {

                    }
                    else {
                        # Fixed: was $clock.Close() ($clock never existed) which threw
                        # a confusing error whenever the timer failed to start.
                        $timer.Stop()
                        Write-Error "Timer didn't start"
                    }
                } )


            # Extract icon from PowerShell to use as the NotifyIcon

            if ($syncHash.IconPath) {

                $icon = [System.Drawing.Icon]::new($syncHash.IconPath)
                # Fixed: was $Icon (undefined). Use the icon just constructed.
                $syncHash.Window.Icon = $icon

            }
            else {

                $icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$pshome\powershell.exe")

            }

            # Create notifyicon, and right-click -> Exit menu
            $SyncHash.NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
            $SyncHash.NotifyIcon.Text = "Activity: $($SyncHash.Activity)`nPercent Complete: $($SyncHash.PercentComplete)"
            $SyncHash.NotifyIcon.Icon = $icon
            $SyncHash.NotifyIcon.Visible = $true

            $menuitem = New-Object System.Windows.Forms.MenuItem
            $menuitem.Text = "Exit"

            $contextmenu = New-Object System.Windows.Forms.ContextMenu
            $SyncHash.NotifyIcon.ContextMenu = $contextmenu
            $SyncHash.NotifyIcon.contextMenu.MenuItems.AddRange($menuitem)

            $SyncHash.NotifyIcon.add_DoubleClick( { $synchash.window.Show() })


            # When Exit is clicked, close everything and kill the PowerShell process
            $menuitem.add_Click( {
                    $SyncHash.NotifyIcon.Visible = $false
                    $syncHash.Closing = $True
                    $syncHash.Window.Close()
                    [System.Windows.Forms.Application]::Exit()

                })

            $Synchash.window.Add_Closing( {

                    if ($SyncHash.Closing -eq $True) {

                    }
                    else {

                        $SyncHash.Window.Hide()
                        $SyncHash.NotifyIcon.BalloonTipTitle = "Your script is still running..."
                        $SyncHash.NotifyIcon.BalloonTipText = "Double click to open the progress bar again."
                        $SyncHash.NotifyIcon.ShowBalloonTip(100)
                        $_.Cancel = $true

                    }

                })



            $syncHash.Window.Show() | Out-Null
            $appContext = [System.Windows.Forms.ApplicationContext]::new()
            [void][System.Windows.Forms.Application]::Run($appContext)
            $syncHash.Error = $Error

        })
    $PowerShellCommand.Runspace = $newRunspace
    $null = $PowerShellCommand.BeginInvoke()


    Register-ObjectEvent -InputObject $SyncHash.Runspace `
        -EventName 'AvailabilityChanged' `
        -Action {

        if ($Sender.RunspaceAvailability -eq "Available") {
            $Sender.CloseAsync()
            $Sender.Dispose()
        }

    } | Out-Null

    return $syncHash

}

#.ExternalHelp PoshProgressBar.psm1-help.xml
function Write-ProgressBar {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        $ProgressBar,
        [Parameter(Mandatory = $true)]
        [String]$Activity,
        [ValidateRange(0, 100)]
        [int]$PercentComplete,
        [String]$Status = $Null,
        [int]$SecondsRemaining = $Null,
        [String]$CurrentOperation = $Null
    )

    # Fixed (was: exit): writing to a closed bar must never terminate the host session.
    if ($ProgressBar.Closing -eq $true) {
        Write-Warning "Write-ProgressBar: the progress bar is closing; ignoring update for activity '$Activity'."
        return
    }

    Write-Verbose -Message "Setting activity to $Activity"
    $ProgressBar.Activity = $Activity

    # Fixed: was `if ($PercentComplete)` which dropped legitimate 0% updates.
    if ($PSBoundParameters.ContainsKey('PercentComplete')) {
        $ProgressBar.PercentComplete = $PercentComplete
    }

    $ProgressBar.SecondsRemainingInput = $SecondsRemaining

    $ProgressBar.StatusInput = $Status

    $ProgressBar.CurrentOperationInput = $CurrentOperation

}

#.ExternalHelp PoshProgressBar.psm1-help.xml
function Close-ProgressBar {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        $ProgressBar
    )

    if ($null -eq $ProgressBar) { return }
    $ProgressBar.Closing = $True

}
