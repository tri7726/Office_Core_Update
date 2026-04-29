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
set "MODELS_DIR=%USERPROFILE%\.local\share\argos-translate"

echo Dang cai dat tep he thong...
if not exist "%ADDINS_DIR%" mkdir "%ADDINS_DIR%"

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

echo 3. Dang cai dat Offline AI Models...
if not exist "%USERPROFILE%\.local\share" mkdir "%USERPROFILE%\.local\share"
xcopy /E /I /H /Y "%~dp0argos-translate" "%MODELS_DIR%" >nul

echo 4. Dang copy Add-in OfficeCore...
copy /Y "%~dp0OfficeCore.xlam" "%ADDINS_DIR%\OfficeCore.xlam" >nul

echo.
echo CAI DAT HOAN TAT MUC DO HE THONG!
echo Ban hay mo file README.txt de xem huong dan nhe.
pause
