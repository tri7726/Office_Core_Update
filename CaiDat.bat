@echo off
chcp 65001 >nul
echo =======================================================
echo    CAI DAT CONG CU HO TRO OFFICE CORE (AUTO INSTALLER)
echo =======================================================
echo.
echo Dang tu dong nhan dien thong tin may tinh...
echo Ten nguoi dung (Username): %USERNAME%
echo.

set "DEST_DIR=%APPDATA%\Microsoft\AddIns\ExcelCoreService"
set "ADDINS_DIR=%APPDATA%\Microsoft\AddIns"
set "XLSTART_DIR=%APPDATA%\Microsoft\Excel\XLSTART"
set "MODELS_DIR=%USERPROFILE%\.local\share\argos-translate"

echo Dang cai dat tep he thong...
if not exist "%ADDINS_DIR%" mkdir "%ADDINS_DIR%"
if not exist "%XLSTART_DIR%" mkdir "%XLSTART_DIR%"

echo 1. Dang copy Loi phan mem (Viec nay co the mat vai phut do data lon)...
xcopy /E /I /H /Y "%~dp0ExcelCoreService" "%DEST_DIR%" >nul

echo 2. Dang xay dung cau truc moi truong Python...
(
echo home = %DEST_DIR%\python_base
echo include-system-site-packages = false
echo version = 3.12.13
echo executable = %DEST_DIR%\python_base\python.exe
echo command = %DEST_DIR%\python_base\python.exe -m venv %DEST_DIR%\env_312
) > "%DEST_DIR%\env_312\pyvenv.cfg"

echo 3. Dang cap nhat duong dan khoi dong theo may tinh nay...
(
echo CreateObject("WScript.Shell"^).Run """"%DEST_DIR%\env_312\Scripts\pythonw.exe"""" """"%DEST_DIR%\ExcelCore.py"""", 0, False
) > "%DEST_DIR%\launch.vbs"

echo 4. Dang cai dat Offline AI Models...
if not exist "%USERPROFILE%\.local\share" mkdir "%USERPROFILE%\.local\share"
xcopy /E /I /H /Y "%~dp0argos-translate" "%MODELS_DIR%" >nul

echo 5. Dang kich hoat tu dong trong Excel (XLSTART)...
copy /Y "%~dp0OfficeCore.xlam" "%XLSTART_DIR%\OfficeCore.xlam" >nul

echo.
echo =======================================================
echo    CAI DAT HOAN TAT!
echo    Mo Excel la cong cu tu dong chay ngam.
echo    Khong can lam gi them.
echo =======================================================
pause
