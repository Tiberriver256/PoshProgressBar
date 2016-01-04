#.ExternalHelp PoshProgressBar.psm1-help.xml
Function New-ProgressBar 
{
 
    param(
        [Parameter(ParameterSetName = "Standard")]
        [Parameter(ParameterSetName='MaterialDesign')]
        [ValidateSet($True,$False)]
        [Bool]$IsIndeterminate = $True,

        [Parameter(Position = 0, Mandatory = $True, ParameterSetName='MaterialDesign')]
        [switch]$MaterialDesign,
        
        [Parameter(ParameterSetName='MaterialDesign')]
        [ValidateSet("Circle","Horizontal","Vertical")]
        [String]$Type = "Horizontal",

        [Parameter(ParameterSetName='MaterialDesign')]
        [ValidateSet("Red","Pink","Purple","DeepPurple","Indigo",
                      "Blue","LightBlue","Cyan","Teal","Green","LightGreen",
                      "Lime","Yellow","Amber","Orange","DeepOrange","Brown",
                      "Grey","BlueGrey")]
        [String]$PrimaryColor = "Blue",

        [Parameter(ParameterSetName='MaterialDesign')]
        [ValidateSet("Red","Pink","Purple","DeepPurple","Indigo",
                      "Blue","LightBlue","Cyan","Teal","Green","LightGreen",
                      "Lime","Yellow","Amber","Orange","DeepOrange")]
        [String]$AccentColor = "LightBlue",

        [Parameter(ParameterSetName = "Standard")]
        [Parameter(ParameterSetName='MaterialDesign')]
        [ValidateSet("Large","Medium","Small")]
        [String]$Size = "Medium",

        [Parameter(ParameterSetName='MaterialDesign')]
        [ValidateSet("Dark","Light")]
        [String]$Theme = "Light"
    )

    $ProgressSize = @{"Small"=140;"Medium"=280;"Large"=560}

    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 
    $syncHash = [hashtable]::Synchronized(@{})
    $newRunspace =[runspacefactory]::CreateRunspace()
    $syncHash.Runspace = $newRunspace
    $syncHash.SecondsRemainingInput = $Null
    $syncHash.StatusInput = ''
    $syncHash.CurrentOperationInput = ''
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
               
               <TextBlock Name="PercentCompleteTextBlock" StackPanel.ZIndex = "99" Text="{Binding ElementName=ProgressBar, Path=Value, StringFormat={}{0:0}%}" HorizontalAlignment="Center" VerticalAlignment="Center" />
               <TextBlock Name="Status" Text="" HorizontalAlignment="Left" />
               <TextBlock Name="TimeRemaining" Text="" HorizontalAlignment="Left" />
               <TextBlock Name="CurrentOperation" Text="" HorizontalAlignment="Left" />
            </StackPanel> 
        </Window> 
"@

    $newRunspace.ApartmentState = "STA" 
    $newRunspace.ThreadOptions = "ReuseThread"           
    $data = $newRunspace.Open() | Out-Null
    $newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
    
    
              
    $PowerShellCommand = [PowerShell]::Create().AddScript({    
 
   
        $syncHash.Window=[Windows.Markup.XamlReader]::parse( $SyncHash.XAML ) 
        #===========================================================================
        # Store Form Objects In PowerShell
        #===========================================================================
        ([xml]$SyncHash.XAML).SelectNodes("//*[@Name]") | %{ $SyncHash."$($_.Name)" = $SyncHash.Window.FindName($_.Name)}
        $TimeRemaining = [System.TimeSpan]

        $updateBlock = {            
            
            $SyncHash.Window.Title = $SyncHash.Activity
            $SyncHash.ProgressBar.Value = $SyncHash.PercentComplete
            if([string]::IsNullOrEmpty($SyncHash.PercentComplete) -ne $True -and $SyncHash.ProgressBar.IsIndeterminate -eq $True)
            {

                $SyncHash.ProgressBar.IsIndeterminate = $False

            }
            $SyncHash.Status.Text = $SyncHash.StatusInput
            if($SyncHash.SecondsRemainingInput)
            {
                $TimeRemaining = [System.TimeSpan]::FromSeconds($SyncHash.SecondsRemainingInput)
                $SyncHash.TimeRemaining.Text = '{0:00}:{1:00}:{2:00}' -f $TimeRemaining.Hours,$TimeRemaining.Minutes,$TimeRemaining.Seconds
            }
            $SyncHash.CurrentOperation.Text = $SyncHash.CurrentOperationInput
            #$SyncHash.Window.MinWidth = $SyncHash.Window.ActualWidth
                       
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
            if( $timer.IsEnabled ) {            
               Write-Host "Clock is running. Don't forget: RIGHT-CLICK to close it."            
            } else {            
               $clock.Close()            
               Write-Error "Timer didn't start"            
            }            
        } )

        $syncHash.Window.ShowDialog() | Out-Null 
        $syncHash.Error = $Error 

    }) 
    $PowerShellCommand.Runspace = $newRunspace 
    $data = $PowerShellCommand.BeginInvoke() 
   
    
    Register-ObjectEvent -InputObject $SyncHash.Runspace `
            -EventName 'AvailabilityChanged' `
            -Action { 
                
                    if($Sender.RunspaceAvailability -eq "Available")
                    {
                        $Sender.Closeasync()
                        $Sender.Dispose()
                    } 
                
                } | Out-Null

    return $syncHash

}

#.ExternalHelp PoshProgressBar.psm1-help.xml
function Write-ProgressBar
{

    Param (
        [Parameter(Mandatory=$true)]
        $ProgressBar,
        [Parameter(Mandatory=$true)]
        [String]$Activity,
        [int]$PercentComplete,
        [String]$Status = $Null,
        [int]$SecondsRemaining = $Null,
        [String]$CurrentOperation = $Null
    ) 
   
   Write-Verbose -Message "Setting activity to $Activity"
   $ProgressBar.Activity = $Activity

   if($PercentComplete)
   {
       
       $ProgressBar.PercentComplete = $PercentComplete

   }
   

    $ProgressBar.SecondsRemainingInput = $SecondsRemaining

    $ProgressBar.StatusInput = $Status

    $ProgressBar.CurrentOperationInput = $CurrentOperation

}

#.ExternalHelp PoshProgressBar.psm1-help.xml
function Close-ProgressBar
{

    Param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]$ProgressBar
    )

    $ProgressBar.Window.Dispatcher.InvokeAsync([action]{ 
      
      $ProgressBar.Window.close()

    }, "Normal")

    $ProgressBar.Runspace.CloseAsync()

}