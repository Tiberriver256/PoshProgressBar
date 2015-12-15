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
    $syncHash.CurrentOperation = ''
    $syncHash.AdditionalInfo = ''
    $newRunspace.ApartmentState = "STA" 
    $newRunspace.ThreadOptions = "ReuseThread"           
    $data = $newRunspace.Open() | Out-Null
    $newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)           
    $PowerShellCommand = [PowerShell]::Create().AddScript({    
        [string]$xaml = @" 
        <Window 
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
            Name="Window" Title="Progress..." WindowStartupLocation = "CenterScreen" 
            Width = "560" Height="130" SizeToContent="Height" ShowInTaskbar = "True"> 
            <StackPanel Margin="20">
               <ProgressBar Width="560" Name="ProgressBar" />
               <TextBlock Text="{Binding ElementName=ProgressBar, Path=Value, StringFormat={}{0:0}%}" HorizontalAlignment="Center" VerticalAlignment="Center" />
               <TextBlock Name="AdditionalInfoTextBlock" Text="" HorizontalAlignment="Center" VerticalAlignment="Center" />
            </StackPanel> 
        </Window> 
"@ 
   
        $syncHash.Window=[Windows.Markup.XamlReader]::parse( $xaml ) 
        #===========================================================================
        # Store Form Objects In PowerShell
        #===========================================================================
        ([xml]$xaml).SelectNodes("//*[@Name]") | %{ $SyncHash."$($_.Name)" = $SyncHash.Window.FindName($_.Name)}

        $updateBlock = {            
            
            $SyncHash.Window.Title = $SyncHash.Activity
            $SyncHash.ProgressBar.Value = $SyncHash.PercentComplete
            $SyncHash.AdditionalInfoTextBlock.Text = $SyncHash.AdditionalInfo
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
       
       Write-Verbose -Message "Setting PercentComplete to $PercentComplete"
       $ProgressBar.PercentComplete = $PercentComplete

   }
   
   if($SecondsRemaining)
   {

       [String]$SecondsRemaining = "$SecondsRemaining Seconds Remaining"

   }
   else
   {

       [String]$SecondsRemaining = $Null

   }

   Write-Verbose -Message "Setting AdditionalInfo to $Status       $SecondsRemaining$(if($SecondsRemaining){ " seconds remaining..." }else {''})       $CurrentOperation"
   $ProgressBar.AdditionalInfo = "$Status       $SecondsRemaining       $CurrentOperation"

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

Write-ProgressBar -ProgressBar $ProgressBar -Activity "Hello" -PercentComplete 50 -CurrentOperation "Counting to 50"

Measure-Command -Expression {
    $Files = dir $env:USERPROFILE -Recurse
    $i = 0
    $Files | foreach {
    
                        $i++
                        Start-Sleep -Milliseconds 10
    
                        Write-ProgressBar `
                                -ProgressBar $ProgressBar `
                                -Activity "Viewing Files" `
                                -PercentComplete (($i/$Files.count) * 100) `
                                -CurrentOperation $_.FullName `
                                -Status $_.Name `
                                -SecondsRemaining (100 - $_.count)
                     }
}