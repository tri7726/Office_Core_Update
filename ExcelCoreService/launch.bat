@echo off
cd /d "C:\Users\Pheo\AppData\Local\Microsoft\Office\Addins\ExcelAddin"
echo Dang khoi dong Microsoft Excel...
echo Vui long cho trong giay lat (5-10 giay)...
".\env\Scripts\python.exe" main.py

if %errorlevel% neq 0 (
    echo.
    echo Co loi xay ra khi khoi dong!
    pause
)
