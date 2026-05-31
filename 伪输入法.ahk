#SingleInstance Force
#Include FileManager.ahk
#Include InputMethodGui.ahk
#Include SettingsGui.ahk

_FileManager := FileManager()
_InputMethodManager := InputMethodManager()
_SettingsGuiManager := SettingsGuiManager()
_FileManager.LoadAllFile()
_InputMethodManager.Create()
_SettingsGuiManager.Create()

Init()

Init() {
    A_HotkeyInterval := 2000
    A_MaxHotkeysPerInterval := 200

    RegisterHotkeys()

    keys := [
        "q","w","e","r","t","y","u","i","o","p","[","]","\",
         "a","s","d","f","g","h","j","k","l",";","'",
          "z","x","c","v","b","n","m",",",".","/"]
    for value IN keys 
        Hotkey(value, k => _InputMethodManager.Show(k))

    HotIf((*)=>WinExist("ahk_id " _InputMethodManager.gui.Hwnd))
    Hotkey("Esc", (*) => _InputMethodManager.Hide())
    
    loop 5 
        Hotkey(A_Index, (*) => _InputMethodManager.OutputContent())
    Hotkey("Space", (*) => _InputMethodManager.OutputContent())
    HotIf()

    ; 菜单项
    try A_TrayMenu.Delete("&Pause Script")
    A_TrayMenu.Insert("1&", "设置(&S)", (*) => _SettingsGuiManager.Show())
    try A_TrayMenu.Rename("&Suspend Hotkeys", "暂停(&P)")
    try A_TrayMenu.Rename("E&xit", "退出(&X)")

    if _FileManager._settingsData.showSettingsOnStart
        _SettingsGuiManager.Show()
}

RegisterHotkeys() {
    static lastSettingsKey := "", lastExitKey := ""

    newSettingsKey := _FileManager._settingsData.hotkeySettings
    newExitKey := _FileManager._settingsData.hotkeyExit

    if lastSettingsKey != ""
        Hotkey(lastSettingsKey, "Off")
    if lastExitKey != ""
        Hotkey(lastExitKey, "Off")

    Hotkey(newSettingsKey, (*) => _SettingsGuiManager.Show(), "On")
    Hotkey(newExitKey, (*) => ExitApp(), "On")

    lastSettingsKey := newSettingsKey
    lastExitKey := newExitKey
}
