' Runs autostart-voiceover.ps1 with no window at all.
' A shortcut to this file lives in the Startup folder, so the Voiceover Studio
' comes back on its own every time the PC is switched on. No admin rights.

Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")

folder = fso.GetParentFolderName(WScript.ScriptFullName)
script = folder & "\autostart-voiceover.ps1"

sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & script & """", 0, False
