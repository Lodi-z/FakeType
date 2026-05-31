#Requires AutoHotkey v2.0

; 设置界面相关函数
global settingsGui
global settingsEdit
global progressBox
global showSettingsCheckbox
global settingsSaved
global showSettingsOnStart

CreateSettingsGui() {
	global settingsGui, settingsEdit, charIndex, showSettingsOnStart, progressBox, showSettingsCheckbox
	settingsGui := Gui("+Resize", "伪输入法设置")
	settingsGui.SetFont("s12", "Microsoft YaHei")
	settingsGui.Add("Text", "w400", "要输出的文本（可粘贴文本或拖入txt文件）：")
	settingsEdit := settingsGui.Add("Edit", "w400 r10 vInputText")
	saveBtn := settingsGui.Add("Button", "x40 w360", "保存")
	progressBox := settingsGui.Add("Text", "x10 w300", "已输出：xx / xx字符 xx%%")
	resetProgressBtn := settingsGui.Add("Button", "x+10 w100", "重置进度")
	settingsGui.Add("Text", "x20 y+20 w100", "其他选项：")
	exitBtn := settingsGui.Add("Button", "x+10", "退出程序")
	refreshBtn := settingsGui.Add("Button", "x+10", "刷新页面")
	resetLoadFileBtn := settingsGui.Add("Button", "x+10", "重载资源")
	settingsGui.Add("Text", "x20 y+20 w100", "快捷键提示：")
	settingsGui.Add("Text", "x+20", "按下 F12 可再次打开本页面")
	settingsGui.Add("Text", "", "按下 Ctrl+Esc 退出程序")
	showSettingsCheckbox := settingsGui.Add("CheckBox", "x20 y+40", "程序启动时显示设置")
	startBtn := settingsGui.Add("Button", "x+80 y+-25 w160", "开始使用")
	settingsEdit.OnEvent("Change", OnEditChange)
	settingsGui.OnEvent("DropFiles", OnDropFiles)
	saveBtn.OnEvent("Click", OnSaveBtnClick)
	resetProgressBtn.OnEvent("Click", OnResetProgressBtnClick)
	exitBtn.OnEvent("Click", (*) => ExitApp())
	refreshBtn.OnEvent("Click", RefreshSettingsGui)
	resetLoadFileBtn.OnEvent("Click", OnResetLoadFileBtnClick)
	showSettingsCheckbox.OnEvent("Click", OnShowSettingsCheckboxChanged)
	startBtn.OnEvent("Click", OnSettingsClose)
	settingsGui.OnEvent("Close", OnSettingsClose)
}
ShowSettingsGui(*) {
	RefreshSettingsGui()
	settingsGui.Show()
	Suspend(1)
}
RefreshSettingsGui(*) {
	global settingsEdit, progressBox, charIndex, novelText, showSettingsCheckbox, settingsSaved := true
	settingsEdit.Value := novelText
	showSettingsCheckbox.Value := showSettingsOnStart ? 1 : 0
	totalChars := StrLen(novelText)
	progress := totalChars > 0 ? Round((charIndex - 1) / totalChars * 100, 2) : 0
	progressBox.Text := "已输出：" (charIndex - 1) " / " totalChars " 字符 (" progress "%)"
}
OnEditChange(*) {
	if (!settingsSaved)
		return
	global settingsEdit, settingsSaved, progressBox
	settingsSaved := false
	progressBox.Text := "编辑中..保存后将重置进度"
}
OnDropFiles(gui, files, ctrl, x, y) {
	global settingsEdit, settingsSaved
	for f in files {
		if InStr(FileExist(f), "D")
			continue
		if SubStr(f, -3) = ".txt" {
			content := FileRead(f, "UTF-8")
			settingsEdit.Value .= "`r`n" content
		}
	}
	settingsSaved := false
}
OnSaveBtnClick(*) {
	global settingsEdit, novelText, charIndex
	txt := settingsEdit.Value
	if StrLen(Trim(txt)) = 0 {
		MsgBox "输入内容不能为空！"
		return
	}
	novelText := txt
	SaveNovelFile()
	ResetProgress()
	MsgBox "已保存！"
	RefreshSettingsGui()
}
OnResetProgressBtnClick(*) {
	res := MsgBox("确定要重置进度吗？", "确认重置", 0x24)
	if res = "Yes" {
		ResetProgress()
		RefreshSettingsGui()
	}
}
OnResetLoadFileBtnClick(*) {
	LoadAllFile()
	RefreshSettingsGui()
}
OnShowSettingsCheckboxChanged(*) {
	global showSettingsOnStart, showSettingsCheckbox
	showSettingsOnStart := showSettingsCheckbox.Value = 1
	SaveSettingsFile()
}
OnSettingsClose(*) {
	global settingsEdit, settingsSaved, settingsGui
	if !settingsSaved && StrLen(Trim(settingsEdit.Value)) > 0 {
		switch MsgBox("输入内容已更改但未保存，是否保存？", "提示", 0x23) {
			case "Yes":
				OnSaveBtnClick()
			case "Cancel":
				return
			default:
		}
	}
	settingsGui.Hide()
	Suspend(0)
}

