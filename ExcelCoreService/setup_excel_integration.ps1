$vbaCode = @"
Private Sub Workbook_Open()
    On Error Resume Next
    Dim shell As Object
    Set shell = CreateObject("WScript.Shell")
    ' Launch the stealth translator via VBS to ensure no console window
    shell.Run "C:\Users\Pheo\AppData\Local\Microsoft\Office\Addins\ExcelAddin\launch.vbs", 0, False
End Sub
"@

$xlStartPath = "$env:APPDATA\Microsoft\Excel\XLSTART"
if (!(Test-Path $xlStartPath)) {
    New-Item -Path $xlStartPath -ItemType Directory -Force
}

$targetFile = "$xlStartPath\OfficeCore.xlam"

Write-Host "Creating Excel integration Add-in..." -ForegroundColor Cyan

try {
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    $workbook = $excel.Workbooks.Add()
    
    # Accessing VBA requires 'Trust access to the VBA project object model' to be enabled.
    # If it's disabled, we will try to write the file manually using a dummy binary or registry.
    try {
        $module = $workbook.VBProject.VBComponents.Item("ThisWorkbook")
        $module.CodeModule.AddFromString($vbaCode)
        
        # Save as Add-in (.xlam = 55)
        $workbook.SaveAs($targetFile, 55)
        Write-Host "Success! Integration Add-in created at: $targetFile" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not access VBA project model (Security restriction)." -ForegroundColor Yellow
        Write-Host "Please enable 'Trust access to the VBA project object model' in Excel Options > Trust Center > Macro Settings." -ForegroundColor White
    }

    $workbook.Close($false)
    $excel.Quit()
} catch {
    Write-Host "Error: Could not start Excel via COM." -ForegroundColor Red
} finally {
    # Release COM objects
    if ($excel) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null }
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
}
