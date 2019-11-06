#.ExternalHelp PoshProgressBar.psm1-help.xml
Function New-ProgressBar {
 
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
        [String]$Theme = "Light"
    )

    $ProgressSize = @{"Small" = 140; "Medium" = 280; "Large" = 560 }

    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | Out-Null
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
            Width = "$($ProgressSize[$Size]+75)" SizeToContent = "Height" ShowInTaskbar = "True"
            
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
               
               <TextBlock Name="PercentCompleteTextBlock" Visibility="Hidden" StackPanel.ZIndex = "99" Text="{Binding ElementName=ProgressBar, Path=Value, StringFormat={}{0:0}%}" HorizontalAlignment="Center" VerticalAlignment="Center" />
               <TextBlock Name="Status" Text="" HorizontalAlignment="Left" />
               <TextBlock Name="TimeRemaining" Text="" HorizontalAlignment="Left" />
               <TextBlock Name="CurrentOperation" Text="" HorizontalAlignment="Left" />
            </StackPanel> 
        </Window> 
"@

    $newRunspace.ApartmentState = "STA" 
    $newRunspace.ThreadOptions = "ReuseThread"           
    $data = $newRunspace.Open() | Out-Null
    $newRunspace.SessionStateProxy.SetVariable("syncHash", $syncHash)
    
    
              
    $PowerShellCommand = [PowerShell]::Create().AddScript( {    
 
   
            $syncHash.Window = [Windows.Markup.XamlReader]::parse( $SyncHash.XAML ) 
            #===========================================================================
            # Store Form Objects In PowerShell
            #===========================================================================
            ([xml]$SyncHash.XAML).SelectNodes("//*[@Name]") | % { $SyncHash."$($_.Name)" = $SyncHash.Window.FindName($_.Name) }
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
                    $timer = new-object System.Windows.Threading.DispatcherTimer            
                    ## Which will fire 4 times every second            
                    $timer.Interval = [TimeSpan]"0:0:0.01"            
                    ## And will invoke the $updateBlock            
                    $timer.Add_Tick( $updateBlock )            
                    ## Now start the timer running            
                    $timer.Start()            
                    if ( $timer.IsEnabled ) {            
                           
                    }
                    else {            
                        $clock.Close()            
                        Write-Error "Timer didn't start"            
                    }            
                } )


            # Extract icon from PowerShell to use as the NotifyIcon

            if ($syncHash.IconPath) {

                $icon = [System.Drawing.Icon]::new($syncHash.IconPath)
                $syncHash.Window.Icon = $Icon

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
    $data = $PowerShellCommand.BeginInvoke() 
   
    
    Register-ObjectEvent -InputObject $SyncHash.Runspace `
        -EventName 'AvailabilityChanged' `
        -Action { 
                
        if ($Sender.RunspaceAvailability -eq "Available") {
            $Sender.Closeasync()
            $Sender.Dispose()
        } 
                
    } | Out-Null

    return $syncHash

}

#.ExternalHelp PoshProgressBar.psm1-help.xml
function Write-ProgressBar {

    Param (
        [Parameter(Mandatory = $true)]
        $ProgressBar,
        [Parameter(Mandatory = $true)]
        [String]$Activity,
        [int]$PercentComplete,
        [String]$Status = $Null,
        [int]$SecondsRemaining = $Null,
        [String]$CurrentOperation = $Null
    ) 
   
    if ($ProgressBar.Closing -eq $true) { exit }

    Write-Verbose -Message "Setting activity to $Activity"
    $ProgressBar.Activity = $Activity

    if ($PercentComplete) {
       
        $ProgressBar.PercentComplete = $PercentComplete

    }
   

    $ProgressBar.SecondsRemainingInput = $SecondsRemaining

    $ProgressBar.StatusInput = $Status

    $ProgressBar.CurrentOperationInput = $CurrentOperation

}

#.ExternalHelp PoshProgressBar.psm1-help.xml
function Close-ProgressBar {

    Param (
        [Parameter(Mandatory = $true)]
        $ProgressBar
    )

    $ProgressBar.Closing = $True

}
