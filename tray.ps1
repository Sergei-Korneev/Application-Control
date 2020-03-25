cls

$apptitle='Application Control 1.0'


$Host.UI.RawUI.WindowTitle = $apptitle
$Host.UI.RawUI.BackgroundColor="DarkMagenta"






#$a=[datetime]::now.date;$a=$a.AddSeconds(15)

#$a.Minute

if (((get-host).version).Major -lt 5 ) {

       
    [System.Windows.Forms.MessageBox]::Show("Please update powerShell to the latest version available.",”Error”)


exit
}

$cudir=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(‘.\’)

Set-Location $cudir
$global:cfile1='Blocked.pc'
$global:cfile2='allowed.pc'






function showNotification($title, $mess, $mode) {
if ($mode -eq 0 -or $mode -eq 1){
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null 
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | out-null 

    $form = New-Object System.Windows.Forms.form
    $form.ShowInTaskbar = $false
    $form.WindowState = "minimized"
    
    $notification = New-Object System.Windows.Forms.NotifyIcon  
    $notification.Icon = "./stop.ico"
    $notification.Visible = $true
    $notification.Text =  $title
    $notification.BalloonTipTitle = $title
    $notification.BalloonTipText = $mess
    $notification.ContextMenu = New-Object System.Windows.Forms.ContextMenu
    
   
 }   

if ($mode  -eq 1){

    



    $menuItem0 = New-Object System.Windows.Forms.MenuItem
    $menuItem0.Text = "Turn off"
    $menuItem0.add_Click({
    
   
    
    #-or   (get-process -ID  $global:app.Id).Id -eq $null
    
    if ( $global:app -eq 0 )
    {
    
    $global:app = Start-Process "powershell.exe" -WorkingDirectory $cudir      -ArgumentList " -File ./appctrl.ps1" -verb runas  -passthru -windowstyle hidden
    $menuItem0.Text = "Turn off"
    }
   

    else {
    $ans1=[System.Windows.Forms.MessageBox]::Show(“Turn off protection?",$apptitle,"YesNo")
    If ($ans1  -eq "Yes"){
    stop-process $global:app.Id 
    $global:app=0
    $menuItem0.Text = "Turn on"
    }
    }
    
    Get-Process 

       
    })



    $menuItem1 = New-Object System.Windows.Forms.MenuItem
    $menuItem1.Text = "Open config files"
    $menuItem1.add_Click({

         Start-Process -FilePath "notepad.exe" -ArgumentList $global:cfile1 
         Start-Process -FilePath "notepad.exe" -ArgumentList $global:cfile2

       # $notification.Dispose()

       #$form.close()
        
    })

    $menuItem2 = New-Object System.Windows.Forms.MenuItem
    $menuItem2.Text = "Exit"
    $menuItem2.add_Click({
    stop-process $global:app.Id 
    #$menuItem0.PerformClick()
        $notification.Dispose()
        $form.close()
       
    })

    $menuItem3 = New-Object System.Windows.Forms.MenuItem
    $menuItem3.Text = "Copy blocked to allowed."
    $menuItem3.add_Click({
    
    Start-Process "cmd.exe" -WorkingDirectory $cudir  -ArgumentList " /k copy.bat"   
    })

    $menuItem4 = New-Object System.Windows.Forms.MenuItem
    $menuItem4.Text = "About"
    $menuItem4.add_Click({
          
    [System.Windows.Forms.MessageBox]::Show('Personal software to protect against unknown malicious executable files.'+ "`r`n" +  "Sergei Korneev 2017”,$apptitle)
    Start-Process -FilePath ($env:ProgramFiles+"\Internet Explorer\iexplore.exe") -ArgumentList ( "-nohome "  + ($cudir+'/donate.htm') )


    }
    
    
    )


    $notification.ContextMenu.MenuItems.AddRange($menuItem0)
    $notification.ContextMenu.MenuItems.AddRange($menuItem1)
    #$notification.ContextMenu.MenuItems.AddRange($menuItem3)
    $notification.ContextMenu.MenuItems.AddRange($menuItem4)
    $notification.ContextMenu.MenuItems.AddRange($menuItem2)

    }

if ($mode -eq 0 -or $mode -eq 1){
    $notification.ShowBalloonTip(10000)
    
    
    
  [void][System.Windows.Forms.Application]::Run($form)

   Unregister-Event -SourceIdentifier click_event -ErrorAction SilentlyContinue 
  

   
}


}


$global:app  = Start-Process "powershell.exe" -WorkingDirectory $cudir  -ArgumentList " -File ./appctrl.ps1" -verb runas  -passthru -windowstyle hidden
showNotification $apptitle  "Hi!" 1
