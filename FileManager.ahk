class FileManager {
	__New() {
	}

	configFile := "settings.ini"
	novelFile := "novel.txt"

	_novelData := NovelData()
	_settingsData := SettingsData()

	; ---------------------------读取--------------------------------

	LoadAllFile() {
		this.LoadProgressFile()
		this.LoadNovelFile()
		this.LoadSettingsFile()
	}

	; 读取小说文件
	LoadNovelFile() {
		if !FileExist(this.novelFile) {
			FileAppend("", this.novelFile, "UTF-8")
			this._novelData.novelText := ""
			return
		}
		try {
			try {
				fileContent := FileRead(this.novelFile, "UTF-8")
			} catch {
				f := FileOpen(this.novelFile, "r")
				fileBytes := f.Read()
				f.Close()
				fileContent := StrGet(fileBytes, "CP936")
			}
			this._novelData.novelText := fileContent
		} catch Error as e {
			MsgBox "无法读取小说文件: " e.Message
			ExitApp
		}
	}

	; 读取进度，若小说文件已变更则重置
	LoadProgressFile() {
		if FileExist(this.configFile) {
			idx := IniRead(this.configFile, "Progress", "CharIndex", 1)
			savedTime := IniRead(this.configFile, "Progress", "NovelFileTime", "")
			fileTime := FileGetTime(this.novelFile, "M")
			if (savedTime != fileTime) {
				this._novelData.charIndex := 1
				this.SaveProgressFile() ; 重置进度文件
				this.SaveNovelFileTime(fileTime)
				return
			}
			this._novelData.charIndex := idx
		}
	}

	; 读取设置文件
	LoadSettingsFile() {
		this._settingsData.showSettingsOnStart := IniRead(this.configFile, "General", "ShowSettingsOnStart", 1)
		this._settingsData.minimalMode := IniRead(this.configFile, "General", "MinimalMode", 0)
		this._settingsData.inputMethodGuiBackColor := IniRead(this.configFile, "InputMethodColor", "BackColor", "")
		this._settingsData.inputMethodGuiforeColor := IniRead(this.configFile, "InputMethodColor", "ForeColor", "")
		this._settingsData.inputMethodGuiTextColor := IniRead(this.configFile, "InputMethodColor", "TextColor", "")
		this._settingsData.hotkeySettings := IniRead(this.configFile, "Hotkeys", "Settings", "F12")
		this._settingsData.hotkeyExit := IniRead(this.configFile, "Hotkeys", "Exit", "^Escape")
	}

	; ---------------------------写入--------------------------------

	; 保存小说文件
	SaveNovelFile() {
		try FileDelete(this.novelFile)
		FileAppend(this._novelData.novelText, this.novelFile, "UTF-8")
	}

	; 保存当前进度
	SaveProgressFile() {
		IniWrite(this._novelData.charIndex, this.configFile, "Progress", "CharIndex")
	}

	; 保存修改时间
	SaveNovelFileTime(fileTime := "") {
		if (fileTime = "")
			fileTime := FileGetTime(this.novelFile, "M")
		IniWrite(fileTime, this.configFile, "Progress", "NovelFileTime")
	}

	; 保存设置文件
	SaveSettingsFile() {
		IniWrite(this._settingsData.showSettingsOnStart, this.configFile, "General", "ShowSettingsOnStart")
		IniWrite(this._settingsData.minimalMode, this.configFile, "General", "MinimalMode")
		IniWrite(this._settingsData.inputMethodGuiBackColor, this.configFile, "InputMethodColor", "BackColor")
		IniWrite(this._settingsData.inputMethodGuiforeColor, this.configFile, "InputMethodColor", "ForeColor")
		IniWrite(this._settingsData.inputMethodGuiTextColor, this.configFile, "InputMethodColor", "TextColor")
		IniWrite(this._settingsData.hotkeySettings, this.configFile, "Hotkeys", "Settings")
		IniWrite(this._settingsData.hotkeyExit, this.configFile, "Hotkeys", "Exit")
	}
}

; ---------------------------数据--------------------------------

class NovelData {
	novelText := ""
	charIndex := 1
	pendingCount := 0
	__ToString() {
		return "NovelData: " this.novelText
	}
}

class SettingsData {
	showSettingsOnStart := true
	minimalMode := false
	inputMethodGuiBackColor := ""
	inputMethodGuiforeColor := ""
	inputMethodGuiTextColor := ""
	hotkeySettings := "F12"
	hotkeyExit := "^Escape"
}