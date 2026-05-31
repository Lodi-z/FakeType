#Requires AutoHotkey v2.0

; 输入法界面相关函数
global inputMethodGui
CreateInputMethodGui() {
	global inputMethodGui
	inputMethodGui := Gui("+AlwaysOnTop +ToolWindow -Caption", "输入法")
	inputMethodGui.BackColor := "80b2da"
	inputMethodGui.SetFont("s12", "Microsoft YaHei")
	inputMethodGui.Add("Edit", "w400 r2 vPreviewText ReadOnly")
	loop 5 {
		inputMethodGui.Add("Text", "w400 vCand" A_Index, "")
	}
	inputMethodGui.MarginX := 10
	inputMethodGui.MarginY := 10
	inputMethodGui.Hide()
	return inputMethodGui
}
ShowInputMethod(*) {
	global inputMethodGui, pendingCount, novelText, charIndex
	pendingCount++
	preview := SubStr(novelText, charIndex, pendingCount)
	try {
		inputMethodGui["PreviewText"].Value := preview
		loop 5 {
			inputMethodGui["Cand" A_Index].Text := A_Index ". " preview
		}
	} catch {
		inputMethodGui := CreateInputMethodGui()
		inputMethodGui["PreviewText"].Value := preview
		loop 5 {
			inputMethodGui["Cand" A_Index].Text := A_Index ". " preview
		}
	}
	if !WinExist("ahk_id " inputMethodGui.Hwnd) {
		shown := false
		try {
			CoordMode("Caret", "Screen")
			CaretGetPos(&x, &y)
			lastPos := "x" x " y" y
			inputMethodGui.Show(lastPos " NA")
			shown := true
		} catch {
			MouseGetPos(&mx, &my)
			lastPos := "x" mx " y" my
			inputMethodGui.Show(lastPos " NA")
		}
	} else {
		inputMethodGui.Show("NA")
	}
}
OutputContent(*) {
	global inputMethodGui, charIndex, pendingCount, novelText
	inputMethodGui.Hide()
	if pendingCount = 0 {
		return
	}
	remain := StrLen(novelText) - charIndex + 1
	toSend := Min(pendingCount, remain)
	if toSend > 0 {
		SendText SubStr(novelText, charIndex, toSend)
		Sleep 100
		charIndex += toSend
	}
	if charIndex > StrLen(novelText) {
		charIndex := 1
	}
	pendingCount := 0
	SaveProgressFile()
}
ResetProgress(*) {
	global charIndex := 1
	SaveProgressFile()
}

