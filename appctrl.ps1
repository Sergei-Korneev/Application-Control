
<#  
    .Description  
    #  
    # AUTHOR: Sergei Korneev 
    # DATE  : 05/14/2017 
    #  
    # COMMENT:  
    #  
    .Example 
    Alternate query for demo 
    $query='Select * from __InstanceModificationEvent WITHIN 1 WHERE TargetInstance ISA "Win32_Service" and targetInstance.Name="bits"' 
    New-WMIEventSubscription -v -query $query -ea stop 
    Get-Service bits|Stop-Service 
    Get-Service bits|Start-Service 
     
    .Example 
    New-WMIEventSubscription -v -commandline 
    Get-Service bits|Stop-Service 
    Get-Service bits|Start-Service 

#> 
#requires -version 5.0 

cls

$apptitle='Application Control 1.0'
$Host.UI.RawUI.WindowTitle = $apptitle
$Host.UI.RawUI.BackgroundColor="DarkMagenta"


if (((get-host).version).Major -lt 5 ) {
write-host "Please update PowerShell to the latest version available."
pause
exit
}




$cdir=$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(‘.\’)
    
Set-Location $cdir
    
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | out-null 
    [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | out-null 

    
  
$global:cfile1='Blocked.pc'
$global:cfile2='allowed.pc'






function initialize(){
$p=(Get-WmiObject win32_process | Where ProcessID -eq  $PID)| select ExecutablePath,ProcessID,ProcessName 
        if ($p.ProcessName -ne $null){
     
[System.IO.File]::AppendAllText($global:cfile2,"")
$s=(Get-FileHash "$( $p.ExecutablePath) " )   | select Hash, Path
     $f2 = [System.IO.File]::ReadAllText($global:cfile2)
         
        $containsWord = $f2 | %{$_ -match $s.Hash}
        if ($containsWord -contains $true) {}
        else{

        [System.IO.File]::AppendAllText($global:cfile2,"")
        $s.Hash +" " +$s.Path  | Add-Content $global:cfile2 
        
        } 
        
}        
         



$paths = ($env:Systemroot+'\system32\notepad.exe'),($env:Systemroot+"\system32\wbem\wmiprvse.exe"),($env:ProgramFiles+"\Internet Explorer\iexplore.exe"),($env:ProgramW6432+"\Internet Explorer\iexplore.exe")
foreach ($path in $paths)
{
$s=(Get-FileHash $path)   | select Hash, Path
        $f2 = [System.IO.File]::ReadAllText($global:cfile2)
         
        $containsWord = $f2 | %{$_ -match $s.Hash}
        if ($containsWord -contains $true) {}
        else{

        [System.IO.File]::AppendAllText($global:cfile2,"")
        $s.Hash +" " +$s.Path  | Add-Content $global:cfile2 
} 

}

}





    $notification = New-Object System.Windows.Forms.NotifyIcon 
    $notification.Icon = "./pr.ico"
    $notification.Visible = $true
    register-objectevent  $notification MouseDoubleClick BalloonMouseDoubleClick_event  -Action {$notification.Visible=$false} 

$timer = new-object timers.timer
$timer.interval=15000
$timer.Enabled=$true
Register-ObjectEvent -InputObject $Timer -EventName Elapsed -SourceIdentifier timer1  -Action { $notification.Visible = $false}



function showNotification($title,$mess) {

    
    $notification.Text =  $mess
    $notification.BalloonTipTitle = $title
    $notification.BalloonTipText = $mess
    $notification.ShowBalloonTip(1000)
    
    $sound = new-Object System.Media.SoundPlayer;
    $sound.SoundLocation=".\notify.wav";
    $sound.Play();
    $sound.Dispose()
    $notification.Visible = $true
    $timer.stop()
    $timer.start()
}




function job1($p,$p2){


    $FOO = {
        Set-Location $args[2]
        $wshell = New-Object -ComObject Wscript.Shell
        [System.IO.File]::AppendAllText($args[1],"")
        [System.IO.File]::AppendAllText($args[5],"")
      
        $y=$wshell.Popup('Add application to exclusion list? ' + "`r`n" +  'Executable path: ' + "`r`n" + $args[0],32,$args[3],4)
        
        

        
        if ($y -eq 6 ) {
        
        $args[4] +" " +$args[0]  | Add-Content $args[1]
       
        $ts=get-content $args[5] | select-string -pattern $args[4] -notmatch 
        set-content  $args[5] $ts
        
    
        
        }

}

    $u=start-Job -ScriptBlock $FOO -Arg $p,$global:cfile2,$cdir,$apptitle,$p2,$global:cfile1


}



function check2($Event){
    $p=(Get-WmiObject win32_process | Where ProcessID -eq  $Event.SourceEventArgs.NewEvent.ProcessId )| select ExecutablePath,ProcessID,ProcessName 
        if ($p.ProcessName -ne $null){
    write-host "> Process |"  $p.ProcessID "|" $p.ProcessName "|" $p.ExecutablePath | Format-Table
    
        
    $s=(Get-FileHash "$( $p.ExecutablePath) " )   | select Hash, Path
    #[System.Windows.Forms.MessageBox]::Show($s.Hash+$s.Path,$apptitle)
    [System.IO.File]::AppendAllText($global:cfile2,"")
    
    $f = [System.IO.File]::ReadAllText($global:cfile2 )
    #$f=Get-Content $global:cfile2

    
    
    $containsWord = $f | %{$_ -match $s.Hash}
        if ($containsWord -contains $true) {


        write-host "<- Whitelisted"
      

        } else {




        Stop-Process -id $p.ProcessID -Force 

        
        write-host "<- Stopped"
        [System.IO.File]::AppendAllText($global:cfile1,"")
        #Add-Content -path $global:cfile1 "---------------"
        $f2 = [System.IO.File]::ReadAllText($global:cfile1)
        #$2=Get-Content $global:cfile1
        $containsWord = $f2 | %{$_ -match $s.Hash}
        if ($containsWord -contains $true) {}
        else{
        showNotification "New application was stopped:" (($s.Path.Substring(0,5)) + " ~ "+  ($s.Path.Substring($s.Path.Length - 15)))
        $s.Hash +" " +$s.Path | Add-Content $global:cfile1
        job1 $s.Path $s.Hash
         

        }

        
}



 }


 }
initialize
function regevent($n){

Register-WMIEvent -Class Win32_ProcessStartTrace -SourceIdentifier "ProcessStarted" -Action {check2($Event) }
}




function unregevent($n){
foreach ($svc in Get-EventSubscriber)
{
 # Unregister-Event $svc.SubscriptionId
  if (  $svc.SourceIdentifier -eq  "ProcessStarted"  ) {Unregister-Event $svc.SubscriptionId}



} 
$notification.Dispose()
Remove-Event BalloonClicked_event -ea SilentlyContinue
Unregister-Event -SourceIdentifier BalloonClicked_event -ea silentlycontinue
Remove-Event BalloonClosed_event -ea SilentlyContinue
Unregister-Event -SourceIdentifier BalloonClosed_event -ea silentlycontinue
Unregister-Event -SourceIdentifier ProcessCheck
Unregister-Event -SourceIdentifier click_event -ErrorAction SilentlyContinue 
Unregister-Event -SourceIdentifier BalloonClicked_event -ErrorAction SilentlyContinue 
Unregister-Event -SourceIdentifier BalloonClosed_event -ErrorAction SilentlyContinue 
Unregister-Event -SourceIdentifier BalloonMouseClick_event -ErrorAction SilentlyContinue 
Unregister-Event -SourceIdentifier BalloonMouseDoubleClick_even -ErrorAction SilentlyContinue 
Unregister-Event -SourceIdentifier BalloonClick_event -ErrorAction SilentlyContinue 
}


regevent
showNotification $apptitle  "Protection started" 1




try{
   
    #We stay in an endless loop to keep the session open
    while($True){
    Wait-Event }
}
catch{

}
finally{
   
unregevent
    
write-host "All bindings are unloaded."
    
}
#Get-EventSubscriber -Force | Unregister-Event -Force