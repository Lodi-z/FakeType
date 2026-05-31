#Requires AutoHotkey v2.0

; 文件管理相关函数
global saveFile := A_ScriptDir "\输入进度.txt"
global novelFile := A_ScriptDir "\这里放小说.txt"
global settingsFile := A_ScriptDir "\伪输入法设置.ini"

LoadAllFile() {
	LoadProgressFile()
	LoadNovelFile()
	LoadSettingsFile()
}
LoadNovelFile() {
	global novelText
	try {
		filePath := A_ScriptDir "\这里放小说.txt"
		try {
			fileContent := FileRead(filePath, "UTF-8")
		} catch {
			f := FileOpen(filePath, "r")
			fileBytes := f.Read()
			f.Close()
			fileContent := StrGet(fileBytes, "CP936")
		}
		novelText := fileContent
		if StrLen(Trim(novelText)) = 0 {
			MsgBox "小说文件为空或没有有效内容"
			ExitApp
		}
	} catch Error as e {
		MsgBox "无法读取小说文件: " e.Message
		ExitApp
	}
}
LoadProgressFile() {
	global charIndex, saveFile, novelFile
	if FileExist(saveFile) {
		content := FileRead(saveFile, "UTF-8")
		arr := StrSplit(content, ",")
		idx := Trim(arr[1])
		savedTime := arr.Length >= 2 ? Trim(arr[2]) : ""
		fileTime := FileGetTime(novelFile, "M")
		if (savedTime != "" && savedTime != fileTime) {
			charIndex := 1
			SaveProgressFile()
			return
		}
		charIndex := idx
	}
}
LoadSettingsFile() {
	global settingsFile, showSettingsOnStart
	showSettingsOnStart := IniRead(settingsFile, "General", "ShowSettingsOnStart", 1)
}
SaveNovelFile() {
	global novelFile, novelText
	try FileDelete(novelFile)
	FileAppend(novelText, novelFile, "UTF-8")
}
SaveProgressFile() {
	global charIndex, saveFile, novelFile
	try FileDelete(saveFile)
	fileTime := FileGetTime(novelFile, "M")
	FileAppend(charIndex "," fileTime, saveFile, "UTF-8")
}
SaveSettingsFile() {
	global showSettingsOnStart
	IniWrite(showSettingsOnStart, settingsFile, "General", "ShowSettingsOnStart")
}

