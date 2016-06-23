$KeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\vmsmp\parameters\SwitchList"
$keys = get-childitem $KeyPath
foreach($key in $keys)
{
   if ($key.GetValue("FriendlyName") -eq 'nat')
   {
      $newKeyPath = $KeyPath+"\"+$key.PSChildName
      Remove-Item -Path $newKeyPath -Recurse
   }
}
remove-netnat -Confirm:$false
Get-ContainerNetwork | Remove-ContainerNetwork -Force

# Get-VmSwitch -Name nat | Remove-VmSwitch #(_failure is expected_)

Stop-Service docker
Set-Service docker -StartupType Disabled

# No need to reboot host 

Get-NetNat | Remove-NetNat
Set-Service docker -StartupType automatic
Start-Service docker