# running mihomo.exe in background without opening cmd
Set objShell = WScript.CreateObject("WScript.Shell")
objShell.Run("C:\Users\xu\.config\mihomo\mihomo.exe"), 0, False
