#SingleInstance Force
#Requires AutoHotkey v2.0

; 引用功能模块
#Include FileManager.ahk
#Include InputMethodGui.ahk
#Include SettingsGui.ahk

global novelText := ""
global charIndex := 1
global pendingCount := 0
global settingsSaved

; 主流程
LoadAllFile()
CreateInputMethodGui()
CreateSettingsGui()
A_HotkeyInterval := 2000
A_MaxHotkeysPerInterval := 200
loop 26 {
    letter := Chr(A_Index + 96)
    Hotkey(letter, ShowInputMethod.Bind())
    Hotkey("+" letter, ShowInputMethod.Bind())
}
Space:: OutputContent()
^Esc:: ExitApp()
F12:: ShowSettingsGui()
A_TrayMenu.Delete()
A_TrayMenu.Add("⚙️ 设置", ShowSettingsGui)
A_TrayMenu.Add("❌ 退出", (*) => ExitApp())
if showSettingsOnStart
    ShowSettingsGui()