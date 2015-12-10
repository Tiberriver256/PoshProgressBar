<# 
.SYNOPSIS   
    This script is used to create a  progress bar 
.DESCRIPTION   
    This script uses a Powershell Runspace to create and manage a WPF progress bar that can be manipulated to show 
    script progress and details.  There are no arguments for this script because it is just an example of how this can be done.   
    The components within the script are what's important for setting this up for your own purposes. 
.NOTES   
    Version        : 1.0 
    Author        : Rhys Edwards 
    Email        : powershell@nolimit.to   
    Credit Due    : Boe Prox wrote in detail about this method of using runspaces and forms, I just applied it to a very  
                                        common problem 
    Link        : http://learn-powershell.net/2012/10/14/powershell-and-wpf-writing-data-to-a-ui-from-a-different-runspace/ 
#> 
 
 
 
# Function to facilitate updates to controls within the window 
Function New-ProgressBar {
 
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 
    $syncHash = [hashtable]::Synchronized(@{})
    $newRunspace =[runspacefactory]::CreateRunspace()
    $syncHash.Runspace = $newRunspace
    $syncHash.Activity = ''
    $syncHash.PercentComplete = 0
    $newRunspace.ApartmentState = "STA" 
    $newRunspace.ThreadOptions = "ReuseThread"           
    $data = $newRunspace.Open() | Out-Null
    $newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)           
    $PowerShellCommand = [PowerShell]::Create().AddScript({    
        [xml]$xaml = @" 
        <Window 
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
            Name="Window" Title="Progress..." WindowStartupLocation = "CenterScreen" 
            Width = "300" Height = "100" ShowInTaskbar = "True"> 
            <StackPanel Margin="20">
               <ProgressBar Name="ProgressBar" />
               <TextBlock Text="{Binding ElementName=ProgressBar, Path=Value, StringFormat={}{0:0}%}" HorizontalAlignment="Center" VerticalAlignment="Center" />
            </StackPanel> 
        </Window> 
"@ 
  
        $reader=(New-Object System.Xml.XmlNodeReader $xaml) 
        $syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader ) 
        #===========================================================================
        # Store Form Objects In PowerShell
        #===========================================================================
        $xaml.SelectNodes("//*[@Name]") | %{ $SyncHash."$($_.Name)" = $SyncHash.Window.FindName($_.Name)}

        $updateBlock = {            
            
            $SyncHash.Window.Title = $SyncHash.Activity
            $SyncHash.ProgressBar.Value = $SyncHash.PercentComplete
                       
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
 

function Write-ProgressBar
{

    Param (
        [Parameter(Mandatory=$true)]
        $ProgressBar,
        [Parameter(Mandatory=$true)]
        [String]$Activity,
        [String]$Status,
        [int]$Id,
        [int]$PercentComplete,
        [int]$SecondsRemaining,
        [String]$CurrentOperation,
        [int]$ParentId,
        [Switch]$Completed,
        [int]$SourceID
    ) 
   
   $ProgressBar.Activity = $Activity

   if($PercentComplete)
   {
      
       $ProgressBar.PercentComplete = $PercentComplete

   }

}


function Close-ProgressBar
{

    Param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]$ProgressBar
    )

    $ProgressBar.Window.Dispatcher.Invoke([action]{ 
      
      $ProgressBar.Window.close()

    }, "Normal")
 
}

$ProgressBar = New-ProgressBar

1..100 | foreach {Write-ProgressBar -ProgressBar $ProgressBar -Activity "Counting $_ out of 100" -PercentComplete $_; Start-Sleep -Milliseconds 10}

Close-ProgressBar $ProgressBar

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 

$objNotifyIcon.Icon = "C:\Users\tiberriver256\Docueents\GitHub\Tiberriver256.GitHub.io\favicon.ico"
$objNotifyIcon.BalloonTipIcon = "Error" 
$objNotifyIcon.BalloonTipText = "A file needed to complete the operation could not be found." 
$objNotifyIcon.BalloonTipTitle = "File Not Found"
 
$objNotifyIcon.Visible = $True 
$objNotifyIcon.ShowBalloonTip(10000)