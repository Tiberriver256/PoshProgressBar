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
    $newRunspace.ApartmentState = "STA" 
    $newRunspace.ThreadOptions = "ReuseThread"           
    $newRunspace.Open() 
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


        ############### New Blog ##############
        $syncHash.Window.Add_Closing({
        
            $_.Cancel = $True;
            $_.Visibility = "Not visible"

            #Show Notification Icon here and add double click event to re-show progress bar
            
            })

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
                
                } 

    return [System.Collections.Hashtable]$SyncHash

}
 

function Write-ProgressBar
{

    Param (
        [Parameter(Mandatory=$true)]
        [System.Object[]]$ProgressBar,
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
   
   # This updates the control based on the parameters passed to the function 
   $ProgressBar.Window.Dispatcher.Invoke([action]{ 
      
      $ProgressBar.Window.Title = $Activity

   }, "Normal")

   if($PercentComplete)
   {

       $ProgressBar.Window.Dispatcher.Invoke([action]{ 
      
          $ProgressBar.ProgressBar.Value = $PercentComplete

       }, "Normal")

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

1..100 | foreach {Write-ProgressBar -ProgressBar $ProgressBar -Activity "Counting $_ out of 100" -PercentComplete $_}

Close-ProgressBar $ProgressBar

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 

$objNotifyIcon.Icon = "C:\Users\tiberriver256\Documents\GitHub\Tiberriver256.GitHub.io\favicon.ico"
$objNotifyIcon.BalloonTipIcon = "Error" 
$objNotifyIcon.BalloonTipText = "A file needed to complete the operation could not be found." 
$objNotifyIcon.BalloonTipTitle = "File Not Found"
 
$objNotifyIcon.Visible = $True 
$objNotifyIcon.ShowBalloonTip(10000)