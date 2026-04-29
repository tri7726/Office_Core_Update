# Fix Microsoft Store Blocking and Execution Aliases
$appDir = "C:\Users\Pheo\AppData\Local\Microsoft\Office\Addins\ExcelAddin"
$aliasPath = "$env:LOCALAPPDATA\Microsoft\WindowsApps"

Write-Host "--- Microsoft Store Block Fixer ---" -ForegroundColor Cyan

# 1. Disable Python Execution Aliases
$aliases = @("python.exe", "python3.exe", "pip.exe", "pip3.exe")
foreach ($alias in $aliases) {
    $fullPath = Join-Path $aliasPath $alias
    if (Test-Path $fullPath) {
        Remove-Item $fullPath -Force -ErrorAction SilentlyContinue
        Write-Host "  - Disabled Store Alias: $alias" -ForegroundColor Green
    }
}

# 2. Unblock files
if (Test-Path $appDir) {
    Get-ChildItem -Path $appDir -Recurse | Unblock-File
    Write-Host "  - Unblocked all files in $appDir" -ForegroundColor Green
}

# 3. Create direct launcher
$launcherPath = Join-Path $appDir "direct_launch.bat"
$pythonPath = Join-Path $appDir "env\Scripts\pythonw.exe"
$mainPy = Join-Path $appDir "main.py"
"@echo off
cd /d `"$appDir`"
start `"`" `"$pythonPath`" `"$mainPy`"
exit" | Out-File -FilePath $launcherPath -Encoding ascii
Write-Host "  - Created: direct_launch.bat" -ForegroundColor Green
