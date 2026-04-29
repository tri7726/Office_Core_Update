$WshShell = New-Object -ComObject WScript.Shell
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$ShortcutPath = [System.IO.Path]::Combine($DesktopPath, "Microsoft Excel.lnk")
$Shortcut = $WshShell.CreateShortcut($ShortcutPath)

# Use the built standalone executable for the best icon and disguise
$Shortcut.TargetPath = "C:\Users\Pheo\.gemini\antigravity\scratch\argos_translator\dist\Excel.exe"
$Shortcut.WorkingDirectory = "C:\Users\Pheo\AppData\Local\Microsoft\Office\Addins\ExcelAddin"

# Set the icon to Excel icon for a better disguise
$ExcelPath = "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE"
if (Test-Path $ExcelPath) {
    $Shortcut.IconLocation = "$ExcelPath,0"
} else {
    $Shortcut.IconLocation = "C:\Users\Pheo\AppData\Local\Microsoft\Office\Addins\ExcelAddin\app_icon.ico"
}

$Shortcut.Save()
Write-Host "Shortcut updated to Microsoft Excel at $ShortcutPath"


