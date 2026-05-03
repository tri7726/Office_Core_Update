@echo off
chcp 65001 >nul
echo =======================================================
echo    CAI DAT CONG CU HO TRO OFFICE CORE (AUTO INSTALLER)
echo =======================================================
echo.
echo Ten nguoi dung (Username): %USERNAME%
echo.

set "DEST_DIR=%APPDATA%\Microsoft\AddIns\ExcelCoreService"
set "ADDINS_DIR=%APPDATA%\Microsoft\AddIns"
set "XLSTART_DIR=%APPDATA%\Microsoft\Excel\XLSTART"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "MODELS_DIR=%USERPROFILE%\.local\share\argos-translate"

if not exist "%ADDINS_DIR%" mkdir "%ADDINS_DIR%"
if not exist "%XLSTART_DIR%" mkdir "%XLSTART_DIR%"

:: -------------------------------------------------------
echo [1/5] Dang copy phan mem (co the mat vai phut)...
xcopy /E /I /H /Y "%~dp0ExcelCoreService" "%DEST_DIR%" >nul

:: Xoa file log/rac ca nhan truoc khi dung (tranh ro ri thong tin)
del /f /q "%DEST_DIR%\app.log"             >nul 2>&1
del /f /q "%DEST_DIR%\debug.txt"           >nul 2>&1
del /f /q "%DEST_DIR%\result.txt"          >nul 2>&1
del /f /q "%DEST_DIR%\test_translate.py"   >nul 2>&1
del /f /q "%DEST_DIR%\direct_launch.bat"   >nul 2>&1
del /f /q "%DEST_DIR%\fix_store.ps1"       >nul 2>&1
del /f /q "%DEST_DIR%\create_shortcut.ps1" >nul 2>&1
del /f /q "%DEST_DIR%\setup_excel_integration.ps1" >nul 2>&1

:: Kiem tra Defender co chan file quan trong khong
if not exist "%DEST_DIR%\env_312\Scripts\pythonw.exe" (
    echo.
    echo *** LOI: Khong tim thay pythonw.exe! ***
    echo Windows Defender co the da chan qua trinh cai dat.
    echo Hay tat Windows Defender tam thoi roi chay lai file nay.
    pause
    exit /b 1
)
if not exist "%DEST_DIR%\ExcelCore.py" (
    echo.
    echo *** LOI: Khong tim thay ExcelCore.py! ***
    pause
    exit /b 1
)
echo    OK - Kiem tra file thanh cong.

:: -------------------------------------------------------
echo [2/5] Dang xay dung moi truong Python...
(
echo home = %DEST_DIR%\python_base
echo include-system-site-packages = false
echo version = 3.12.13
echo executable = %DEST_DIR%\python_base\python.exe
echo command = %DEST_DIR%\python_base\python.exe -m venv %DEST_DIR%\env_312
) > "%DEST_DIR%\env_312\pyvenv.cfg"

:: -------------------------------------------------------
echo [3/5] Dang cap nhat duong dan theo may tinh nay...
(
echo Set ws = CreateObject("WScript.Shell"^)
echo dest = ws.ExpandEnvironmentStrings("%%APPDATA%%\Microsoft\AddIns\ExcelCoreService"^)
echo ws.Run """" ^& dest ^& "\env_312\Scripts\pythonw.exe"" """ ^& dest ^& "\ExcelCore.py""", 0, False
) > "%DEST_DIR%\launch.vbs"

:: -------------------------------------------------------
echo [4/5] Dang cai dat AI Models...
if not exist "%USERPROFILE%\.local\share" mkdir "%USERPROFILE%\.local\share"
xcopy /E /I /H /Y "%~dp0argos-translate" "%MODELS_DIR%" >nul

:: -------------------------------------------------------
echo [5/5] Dang kich hoat tu dong trong Excel...

:: Mo khoa VBA cho TAT CA phien ban Office pho bien
:: (12.0=2007, 14.0=2010, 15.0=2013, 16.0=2016/2019/365)
for %%v in (12.0 14.0 15.0 16.0) do (
    reg add "HKCU\Software\Microsoft\Office\%%v\Excel\Security" /v AccessVBOM /t REG_DWORD /d 1 /f >nul 2>&1
)

:: Tao xlam moi bang PowerShell COM (tu dong theo duong dan may nay)
set "XLAM_OK=0"
powershell -ExecutionPolicy Bypass -Command ^
  "$dest = $env:APPDATA + '\Microsoft\AddIns\ExcelCoreService';" ^
  "$xlstart = $env:APPDATA + '\Microsoft\Excel\XLSTART';" ^
  "$code  = 'Private Sub Workbook_Open()' + [char]10;" ^
  "$code += '    On Error Resume Next' + [char]10;" ^
  "$code += '    CreateObject(""WScript.Shell"").Run ""' + $dest + '\launch.vbs"", 0, False' + [char]10;" ^
  "$code += 'End Sub';" ^
  "try {" ^
  "  $xl = New-Object -ComObject Excel.Application;" ^
  "  $xl.Visible = $false; $xl.DisplayAlerts = $false;" ^
  "  $wb = $xl.Workbooks.Add();" ^
  "  $wb.VBProject.VBComponents.Item('ThisWorkbook').CodeModule.AddFromString($code);" ^
  "  $wb.SaveAs($xlstart + '\OfficeCore.xlam', 55);" ^
  "  $wb.Close($false); $xl.Quit();" ^
  "  exit 0" ^
  "} catch { exit 1 }"

if %errorlevel% == 0 (
    echo    OK - Tao OfficeCore.xlam thanh cong.
    set "XLAM_OK=1"
) else (
    echo    CANH BAO: Khong the tu tao xlam, dang dung ban du phong...
    copy /Y "%~dp0OfficeCore.xlam" "%XLSTART_DIR%\OfficeCore.xlam" >nul 2>&1
    if exist "%XLSTART_DIR%\OfficeCore.xlam" (
        echo    OK - Da copy xlam du phong vao XLSTART.
    ) else (
        echo    CANH BAO: Ca hai cach deu that bai. Xem README.txt phan Xu ly su co.
    )
)

:: Dong khoa VBA lai cho tat ca phien ban
for %%v in (12.0 14.0 15.0 16.0) do (
    reg delete "HKCU\Software\Microsoft\Office\%%v\Excel\Security" /v AccessVBOM /f >nul 2>&1
)

:: Them vao Startup lam du phong (chay ngam ngay khi dang nhap Windows)
copy /Y "%DEST_DIR%\launch.vbs" "%STARTUP_DIR%\OfficeCoreService.vbs" >nul 2>&1
echo    OK - Da them vao Startup (du phong).

echo.
echo =======================================================
echo    CAI DAT HOAN TAT!
echo.
echo    KIEM TRA NGAY: Mo Excel len, doi 3 giay,
echo    nhan Ctrl + Shift + X
echo    Neu thay cua so hien ra la THANH CONG 100%%!
echo =======================================================
pause
