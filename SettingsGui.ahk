#Include <ColorTools>

class SettingsGuiManager {
    _novelData {
        get => _FileManager._novelData
        set => _FileManager._novelData := Value
    }
    _settingsData {
        get => _FileManager._settingsData
        set => _FileManager._settingsData := Value
    }
    settingsGui := ""
    _textDirty := false
    _colorsDirty := false
    _hotkeysDirty := false
    _lastSearchText := ""
    _lastSearchPos := 0

    static presetColors := [
    "FFFFFF", 
    "000000", 
    "FF3B30", 
    "FF9500", 
    "FFCC00", 
    "34C759", 
    "00C7BE", 
    "32ADE6", 
    "007AFF", 
    "5856D6", 
    "AF52DE", 
    "FF2D55", 
    "8E8E93", 
    "E5E5EA"  
    ]

    _paragraphs := []
    _paragraphsValid := false
    _novelEditText := ""

    Create() {
        this.settingsGui := Gui(, "伪输入法 - 设置中心")
        this.settingsGui.SetFont("s9", "Microsoft YaHei UI")
        this.settingsGui.BackColor := "FAFAFA"
        this.settingsGui.MarginX := 15
        this.settingsGui.MarginY := 10

        this._CreateTextSection()
        this._CreateProgressSection()
        this._CreateColorSection()
        this._CreateHotkeySection()
        this._CreateBottomSection()

        this.settingsGui.OnEvent("DropFiles", (GuiObj, GuiCtrlObj, FileArray, X, Y) => this.OnDropFiles(FileArray))
        this.settingsGui.OnEvent("Close", (*) => this.Hide())
    }

    _CreateTextSection() {
        this.settingsGui.SetFont("s10 bold")
        this.settingsGui.AddGroupBox("x15 y10 w570 h200", " 文本内容")
        this.settingsGui.SetFont("s9 norm")
        this.settingsGui.AddText("x30 y32 w540", "可直接粘贴文本，或拖入 txt 文件：")
        this.settingsGui.AddEdit("x30 y55 w540 h110 vNovelEdit").OnEvent("Change", (*) => this.OnNovelEditChange())
        this.settingsGui.AddButton("x30 y175 w540 h30 vSaveNovelBtn", "保存文本内容").OnEvent("Click", (*) => this.OnSaveNavelBtnClick())
    }

    _CreateProgressSection() {
        this.settingsGui.SetFont("s10 bold")
        this.settingsGui.AddGroupBox("x15 y220 w570 h225", " 输入进度")
        this.settingsGui.SetFont("s9 norm")

        this.settingsGui.AddText("x30 y242 w540 h22 +Border +Center vProgressBox", "已输出：0 / 0 字符 (0%)")

        this.settingsGui.AddText("x30 y272 w40 h22 +0x200", "段落")
        this.settingsGui.AddSlider("x75 y274 w380 h22 ToolTip Range1-1 vParagraphSlider")
        this.settingsGui["ParagraphSlider"].OnEvent("Change", ObjBindMethod(this, "OnSliderChange"))
        this.settingsGui.AddText("x460 y272 w105 h22 +0x200 vParagraphLabel", "0 / 0")

        this.settingsGui.AddButton("x30 y300 w65 h24 vPrevParaBtn", "上一段").OnEvent("Click", (*) => this.OnPrevParagraph())
        this.settingsGui.AddButton("x100 y300 w65 h24 vNextParaBtn", "下一段").OnEvent("Click", (*) => this.OnNextParagraph())
        this.settingsGui.AddButton("x170 y300 w65 h24 vResetProgressBtn", "重置进度").OnEvent("Click", (*) => this.OnResetProgressBtnClick())
        this.settingsGui.AddText("x245 y302 w200 c808080", "保存新文本后进度将自动重置")

        this.settingsGui.AddEdit("x30 y330 w540 h80 ReadOnly vProgressPreview")

        this.settingsGui.AddEdit("x30 y420 w440 h22 vSearchEdit").OnEvent("Change", (*) => this.OnSearchEditChange())
        this.settingsGui.AddButton("x475 y420 w90 h22 vSearchBtn", "搜索文本").OnEvent("Click", (*) => this.OnSearchBtnClick())
    }

    _CreateColorSection() {
        this.settingsGui.SetFont("s10 bold")
        this.settingsGui.AddGroupBox("x15 y455 w570 h168", " 输入法外观")
        this.settingsGui.SetFont("s9 norm")

        colorTypes := [["Back", "背景色"], ["Fore", "前景色"], ["Text", "文字色"]]
        rowY := 480

        for typeInfo in colorTypes {
            typeKey := typeInfo[1]
            typeLabel := typeInfo[2]

            this.settingsGui.AddText("x30 y" rowY " w65 h24 +0x200", typeLabel)

            xSwatch := 95
            for color in SettingsGuiManager.presetColors {
                swatchName := typeKey "Swatch" color
                this.settingsGui.AddText("x" xSwatch " y" rowY " w22 h22 +0x200 +Border Background" color " v" swatchName, "  ")
                this.settingsGui[swatchName].OnEvent("Click", ObjBindMethod(this, "OnPresetClick", typeKey, color))
                xSwatch += 25
            }

            editCtrl := this.settingsGui.AddEdit("x455 y" rowY " w75 h22 vInputMethod" typeKey "ColorEdit Uppercase Limit6")
            editCtrl.OnEvent("Change", ObjBindMethod(this, "OnColorEditChange", typeKey))

            this.settingsGui.AddText("x535 y" rowY " w36 h22 +0x200 +Border v" typeKey "ColorPreview BackgroundE0E0E0", "  ")

            rowY += 33
        }

        this.settingsGui.AddButton("x30 y585 w540 h30 vSaveColorBtn", "应用颜色设置").OnEvent("Click", (*) => this.OnSaveColorBtnClick())
    }

    _CreateHotkeySection() {
        this.settingsGui.SetFont("s10 bold")
        this.settingsGui.AddGroupBox("x15 y633 w570 h75", " 快捷键设置（修改后点击应用生效）")
        this.settingsGui.SetFont("s9 norm")

        this.settingsGui.AddText("x30 y658 w100 h22 +0x200", "打开设置界面")
        ctrl1 := this.settingsGui.AddHotkey("x135 y658 w130 h22 vHotkeySettingsCtrl")
        ctrl1.OnEvent("Change", (*) => this._hotkeysDirty := true)
        this.settingsGui.AddText("x280 y658 w60 h22 +0x200", "退出程序")
        ctrl2 := this.settingsGui.AddHotkey("x340 y658 w130 h22 vHotkeyExitCtrl")
        ctrl2.OnEvent("Change", (*) => this._hotkeysDirty := true)
        this.settingsGui.AddButton("x480 y657 w90 h24 vSaveHotkeyBtn", "应用快捷键").OnEvent("Click", (*) => this.OnSaveHotkeyBtnClick())
    }

    _CreateBottomSection() {
        this.settingsGui.AddCheckbox("x15 y718 vShowSettingsOnStart", "程序启动时显示设置中心").OnEvent("Click", (*) => this.OnShowSettingsCheckboxChanged())
        this.settingsGui.AddCheckbox("x15 y738 vMinimalMode", "极简模式（只显示一行）").OnEvent("Click", (*) => this.OnMinimalModeCheckboxChanged())
        this.settingsGui.AddText("x370 y720 w80 h22 c808080 +Right", "作者：洛迪")
        this.settingsGui.AddButton("x15 y768 w100 h35 vExitBtn", "退出程序").OnEvent("Click", (*) => this.OnExitBtnClick())
        this.settingsGui.AddButton("x125 y768 w100 h35 vRefreshBtn", "刷新").OnEvent("Click", (*) => this.OnResetLoadFileBtnClick())
        this.settingsGui.AddButton("x235 y768 w100 h35 vDonateBtn", "支持作者").OnEvent("Click", (*) => Run("https://ifdian.net/a/luodi"))
        this.settingsGui.SetFont("s11 bold")
        this.settingsGui.AddButton("x465 y768 w120 h35 vStartBtn Default", "开始使用").OnEvent("Click", (*) => this.Hide())
        this.settingsGui.SetFont("s9 norm")
    }

    Show() {
        this._InvalidateParagraphs()
        this._ClearDirty()
        this.Refresh()
        this.settingsGui.Show("w600 h820")
        this.settingsGui["StartBtn"].focus()
        Suspend(true)
        _InputMethodManager.Hide()
    }

    Refresh() {
        if this._novelData.novelText != this._novelEditText {
            this.settingsGui["NovelEdit"].Opt("-Redraw")
            this.settingsGui["NovelEdit"].Value := this._novelData.novelText
            this.settingsGui["NovelEdit"].Opt("+Redraw")
            this._novelEditText := this._novelData.novelText
        }
        this.settingsGui["InputMethodBackColorEdit"].Value := this._settingsData.inputMethodGuiBackColor
        this.settingsGui["InputMethodForeColorEdit"].Value := this._settingsData.inputMethodGuiforeColor
        this.settingsGui["InputMethodTextColorEdit"].Value := this._settingsData.inputMethodGuiTextColor
        this.settingsGui["ShowSettingsOnStart"].Value := this._settingsData.showSettingsOnStart
        this.settingsGui["MinimalMode"].Value := this._settingsData.minimalMode
        this.settingsGui["HotkeySettingsCtrl"].Value := this._settingsData.hotkeySettings
        this.settingsGui["HotkeyExitCtrl"].Value := this._settingsData.hotkeyExit

        totalChars := StrLen(this._novelData.novelText)
        progress := totalChars > 0 ? Round((this._novelData.charIndex - 1) / totalChars * 100, 2) : 0
        this.settingsGui["ProgressBox"].Text := "已输出：" (this._novelData.charIndex - 1) " / " totalChars " 字符 (" progress "%)"

        this._EnsureParagraphs()
        paraCount := this._paragraphs.Length
        currentPara := this._GetCurrentParagraph()
        this.settingsGui["ParagraphLabel"].Text := currentPara " / " paraCount
        this.settingsGui["ParagraphSlider"].Opt("+Range1-" paraCount)
        this.settingsGui["ParagraphSlider"].Value := currentPara

        this._UpdateProgressPreview()

        this._UpdateColorPreview("Back", this._settingsData.inputMethodGuiBackColor)
        this._UpdateColorPreview("Fore", this._settingsData.inputMethodGuiforeColor)
        this._UpdateColorPreview("Text", this._settingsData.inputMethodGuiTextColor)
    }

    _ClearDirty() {
        this._textDirty := false
        this._colorsDirty := false
        this._hotkeysDirty := false
    }

    _AnyDirty() {
        return this._textDirty || this._colorsDirty || this._hotkeysDirty
    }

    _BuildDirtyMsg() {
        msg := "以下内容已更改但未保存：`n"
        if this._textDirty
            msg .= "  • 文本内容`n"
        if this._colorsDirty
            msg .= "  • 颜色设置`n"
        if this._hotkeysDirty
            msg .= "  • 快捷键设置`n"
        msg .= "是否保存后再继续？"
        return msg
    }

    _UpdateProgressPreview() {
        totalChars := StrLen(this._novelData.novelText)
        if totalChars = 0 {
            this.settingsGui["ProgressPreview"].Value := ""
            return
        }
        currentIdx := this._novelData.charIndex
        start := Max(1, currentIdx - 20)
        end := Min(totalChars, currentIdx + 50)
        before := SubStr(this._novelData.novelText, start, currentIdx - start)
        after := SubStr(this._novelData.novelText, currentIdx, end - currentIdx + 1)

        this.settingsGui["ProgressPreview"].Value := before "👉" after
    }

    _EnsureParagraphs() {
        if this._paragraphsValid
            return
        this._paragraphs := []
        text := this._novelData.novelText
        if StrLen(text) = 0 {
            this._paragraphs.Push({startIdx: 1, text: ""})
        } else {
            pos := 1
            Loop Parse, text, "`n" {
                line := A_LoopField
                hasR := StrLen(line) > 0 && SubStr(line, -1) = "`r"
                if hasR
                    line := SubStr(line, 1, -1)
                if Trim(line) = "" {
                    pos += (hasR ? 2 : 1)
                    continue
                }
                this._paragraphs.Push({startIdx: pos, text: line})
                pos += StrLen(line) + (hasR ? 2 : 1)
            }
            if this._paragraphs.Length = 0
                this._paragraphs.Push({startIdx: 1, text: ""})
        }
        this._paragraphsValid := true
    }

    _InvalidateParagraphs() {
        this._paragraphsValid := false
    }

    _GetCurrentParagraph() {
        this._EnsureParagraphs()
        currentIdx := this._novelData.charIndex
        for i, para in this._paragraphs {
            if currentIdx < para.startIdx
                return Max(1, i - 1)
        }
        return this._paragraphs.Length
    }

    _UpdateToParagraph(paraNum) {
        this._EnsureParagraphs()
        if paraNum < 1 || paraNum > this._paragraphs.Length
            return
        newIdx := this._paragraphs[paraNum].startIdx
        if newIdx = this._novelData.charIndex
            return
        this._novelData.charIndex := newIdx
        _FileManager.SaveProgressFile()
        _InputMethodManager.ClearCompletion()

        totalChars := StrLen(this._novelData.novelText)
        progress := totalChars > 0 ? Round((newIdx - 1) / totalChars * 100, 2) : 0
        this.settingsGui["ProgressBox"].Text := "已输出：" (newIdx - 1) " / " totalChars " 字符 (" progress "%)"
        this.settingsGui["ParagraphLabel"].Text := paraNum " / " this._paragraphs.Length
        this._UpdateProgressPreview()
    }

    OnSliderChange(GuiCtrlObj, *) {
        paraNum := GuiCtrlObj.Value
        currentPara := this._GetCurrentParagraph()
        if paraNum = currentPara
            return
        this._UpdateToParagraph(paraNum)
    }

    OnPrevParagraph() {
        currentPara := this._GetCurrentParagraph()
        if currentPara > 1
            this._UpdateToParagraph(currentPara - 1)
    }

    OnNextParagraph() {
        this._EnsureParagraphs()
        currentPara := this._GetCurrentParagraph()
        if currentPara < this._paragraphs.Length
            this._UpdateToParagraph(currentPara + 1)
    }

    OnNovelEditChange() {
        this._textDirty := true
        this.settingsGui["ProgressBox"].Text := "编辑中...保存后将重置进度"
    }

    OnSearchEditChange() {
        this._lastSearchText := ""
        this._lastSearchPos := 0
    }

    OnSearchBtnClick() {
        searchText := this.settingsGui["SearchEdit"].Value
        if searchText = "" {
            return
        }

        novelText := this._novelData.novelText
        totalChars := StrLen(novelText)
        if totalChars = 0 {
            return
        }

        if searchText != this._lastSearchText {
            this._lastSearchPos := this._novelData.charIndex
            this._lastSearchText := searchText
        }

        foundPos := InStr(novelText, searchText, true, this._lastSearchPos)

        if foundPos = 0 {
            foundPos := InStr(novelText, searchText, true, 1)
            if foundPos = 0 {
                MsgBox "未找到：" searchText, "搜索", 64 " Owner" this.settingsGui.Hwnd
                return
            }
        }

        this._novelData.charIndex := foundPos
        this._lastSearchPos := foundPos + 1
        _FileManager.SaveProgressFile()
        _InputMethodManager.ClearCompletion()

        this._InvalidateParagraphs()
        this.Refresh()
    }

    OnDropFiles(files) {
        newValue := ""
        for f in files {
            if InStr(FileExist(f), "D")
                continue
            if SubStr(f, -4) = ".txt" {
                content := FileRead(f, "UTF-8")
                newValue .= content
            }
            else
                MsgBox "拖入的文件" f "并非txt格式",, "Owner" this.settingsGui.Hwnd
        }
        if (newValue != "") {
            this.settingsGui["NovelEdit"].Value := newValue
            this.OnNovelEditChange()
        }
    }

    OnSaveNavelBtnClick() {
        txt := this.settingsGui["NovelEdit"].Value
        this._novelData.novelText := txt
        _FileManager.SaveNovelFile()
        _InputMethodManager.ResetProgress()
        this._InvalidateParagraphs()
        this._novelEditText := txt
        this._textDirty := false
        this._lastSearchText := ""
        this._lastSearchPos := 0
        this.settingsGui["SearchEdit"].Value := ""
        MsgBox "已保存！",, "Owner" this.settingsGui.Hwnd
        this.Refresh()
    }

    OnResetProgressBtnClick() {
        res := MsgBox("确定要重置进度吗？", "确认重置", 0x24 " Owner" this.settingsGui.Hwnd)
        if res = "Yes" {
            _InputMethodManager.ResetProgress()
            this._lastSearchText := ""
            this._lastSearchPos := 0
            this.settingsGui["SearchEdit"].Value := ""
            this.Refresh()
        }
    }

    OnPresetClick(typeKey, color, GuiCtrlObj, *) {
        editName := "InputMethod" typeKey "ColorEdit"
        this.settingsGui[editName].Value := color
        this._UpdateColorPreview(typeKey, color)
        this._colorsDirty := true
    }

    OnColorEditChange(typeKey, GuiCtrlObj, *) {
        editName := "InputMethod" typeKey "ColorEdit"
        color := this.settingsGui[editName].Value
        this._UpdateColorPreview(typeKey, color)
        this._colorsDirty := true
    }

    _UpdateColorPreview(typeKey, color) {
        previewName := typeKey "ColorPreview"
        if (RegExMatch(color, "^[0-9A-Fa-f]{6}$")) {
            this.settingsGui[previewName].Opt("+Background" color)
            this.settingsGui[previewName].Redraw()
        } else {
            this.settingsGui[previewName].Opt("+BackgroundE0E0E0")
            this.settingsGui[previewName].Redraw()
        }
    }

    OnSaveColorBtnClick() {
        backColor := this.settingsGui["InputMethodBackColorEdit"].Value
        foreColor := this.settingsGui["InputMethodForeColorEdit"].Value
        textColor := this.settingsGui["InputMethodTextColorEdit"].Value

        if (!RegExMatch(backColor, "^[0-9A-Fa-f]{6}$") && backColor != "") {
            MsgBox "背景色格式错误！请输入6位十六进制颜色代码", "错误", 16 " Owner" this.settingsGui.Hwnd
            return
        }
        if (!RegExMatch(foreColor, "^[0-9A-Fa-f]{6}$") && foreColor != "") {
            MsgBox "前景色格式错误！请输入6位十六进制颜色代码", "错误", 16 " Owner" this.settingsGui.Hwnd
            return
        }
        if (!RegExMatch(textColor, "^[0-9A-Fa-f]{6}$") && textColor != "") {
            MsgBox "文字色格式错误！请输入6位十六进制颜色代码", "错误", 16 " Owner" this.settingsGui.Hwnd
            return
        }

        this._settingsData.inputMethodGuiBackColor := backColor
        this._settingsData.inputMethodGuiforeColor := foreColor
        this._settingsData.inputMethodGuiTextColor := textColor
        _FileManager.SaveSettingsFile()

        _InputMethodManager.SetColor(0, backColor)
        _InputMethodManager.SetColor(1, foreColor)
        _InputMethodManager.SetColor(2, textColor)

        this._colorsDirty := false
        MsgBox "颜色设置已应用并保存！", "成功", 64 " Owner" this.settingsGui.Hwnd
    }

    OnSaveHotkeyBtnClick() {
        newSettingsKey := this.settingsGui["HotkeySettingsCtrl"].Value
        newExitKey := this.settingsGui["HotkeyExitCtrl"].Value

        if newSettingsKey = "" || newExitKey = "" {
            MsgBox "快捷键不能为空！", "错误", 16 " Owner" this.settingsGui.Hwnd
            return
        }

        try {
            Hotkey(newSettingsKey, (*) => ExitApp(), "Off")
        } catch {
            MsgBox "快捷键格式错误：" newSettingsKey "，请使用 AHK 热键格式（如 F12、^Escape）", "错误", 16 " Owner" this.settingsGui.Hwnd
            return
        }
        try {
            Hotkey(newExitKey, (*) => ExitApp(), "Off")
        } catch {
            MsgBox "快捷键格式错误：" newExitKey "，请使用 AHK 热键格式（如 F12、^Escape）", "错误", 16 " Owner" this.settingsGui.Hwnd
            return
        }

        this._settingsData.hotkeySettings := newSettingsKey
        this._settingsData.hotkeyExit := newExitKey
        _FileManager.SaveSettingsFile()

        RegisterHotkeys()

        this._hotkeysDirty := false
        MsgBox "快捷键已更新！", "成功", 64 " Owner" this.settingsGui.Hwnd
    }

    OnExitBtnClick() {
        if !this._CheckAndSave()
            return
        ExitApp()
    }

    OnResetLoadFileBtnClick() {
        _FileManager.LoadAllFile()
        this._novelEditText := ""
        this._InvalidateParagraphs()
        this._ClearDirty()
        this._lastSearchText := ""
        this._lastSearchPos := 0
        this.settingsGui["SearchEdit"].Value := ""
        this.Refresh()
    }

    OnShowSettingsCheckboxChanged() {
        this._settingsData.showSettingsOnStart := this.settingsGui["ShowSettingsOnStart"].Value
        _FileManager.SaveSettingsFile()
    }

    OnMinimalModeCheckboxChanged() {
        this._settingsData.minimalMode := this.settingsGui["MinimalMode"].Value
        _FileManager.SaveSettingsFile()
    }

    Hide() {
        if !this._CheckAndSave()
            return
        this.settingsGui.Hide()
        Suspend(false)
    }

    _CheckAndSave() {
        if !this._AnyDirty()
            return true
        switch MsgBox(this._BuildDirtyMsg(), "提示", 0x23 " Owner" this.settingsGui.Hwnd) {
            case "Yes":
                this._SaveAllDirty()
            case "Cancel":
                return false
            default:
        }
        return true
    }

    _SaveAllDirty() {
        if this._textDirty
            this.OnSaveNavelBtnClick()
        if this._colorsDirty
            this.OnSaveColorBtnClick()
        if this._hotkeysDirty
            this.OnSaveHotkeyBtnClick()
        this._ClearDirty()
    }
}
