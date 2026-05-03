@echo off
chcp 65001 >nul
echo =======================================================
echo    LENH GO CAI DAT OFFICE CORE (XOA DAU VET)
echo =======================================================
echo.
echo Dang tien hanh xoa moi dau vet khoi he thong...

:: 1. Xoa thu muc phan mem trong AppData
set "TARGET_DIR=%APPDATA%\Microsoft\AddIns\ExcelCoreService"
if exist "%TARGET_DIR%" (
    echo - Dang xoa bo ma nguon...
    rmdir /s /q "%TARGET_DIR%"
)

:: 2. Xoa file Add-in kich hoat (vi tri mac dinh trong AddIns)
set "ADDIN_FILE=%APPDATA%\Microsoft\AddIns\OfficeCore.xlam"
if exist "%ADDIN_FILE%" (
    echo - Dang xoa file Add-in (AddIns)...
    del /f /q "%ADDIN_FILE%"
)

:: 3. Xoa file Add-in trong XLSTART (vi tri tu dong chay cung Excel)
set "XLSTART_FILE=%APPDATA%\Microsoft\Excel\XLSTART\OfficeCore.xlam"
if exist "%XLSTART_FILE%" (
    echo - Dang xoa file Add-in (XLSTART)...
    del /f /q "%XLSTART_FILE%"
)

:: 4. Xoa nao AI (Model dich thuat)
set "MODELS_DIR=%USERPROFILE%\.local\share\argos-translate"
if exist "%MODELS_DIR%" (
    echo - Dang xoa du lieu AI Models...
    rmdir /s /q "%MODELS_DIR%"
)

:: 5. Xoa khoa Registry da dang ky
echo - Dang xoa dang ky he thong (Registry)...
reg delete "HKCU\Software\Microsoft\Office\Excel\AddIns\ExcelCoreService" /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Office\Excel\AddIns\ExcelCoreService" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\ExcelCoreService" /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\ExcelCoreService" /f >nul 2>&1

echo.
echo =======================================================
echo    DA GO CAI DAT THANH CONG!
echo    Moi dau vet da duoc xoa sach khoi may tinh.
echo =======================================================
pause
