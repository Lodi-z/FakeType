class InputMethodPartType {
    static back := 0
    static fore := 1
    static text := 2
}
ScaleFactor := A_ScreenDPI / 96
class InputMethodManager {
    __New() {
        CoordMode "Caret", "Screen"
        CoordMode "Mouse", "Screen"
        CoordMode "ToolTip", "Screen"
    }
    /**@type {Gui}*/
    gui := ""
    _novelData := NovelData()
    _inputKeys := ""
    _isCompleted := false
    _lastWinW := 0

    Create() {
        ; 保证_novelData为对象
        if IsObject(_FileManager._novelData)
            this._novelData := _FileManager._novelData
        else
            this._novelData := NovelData()
        this.gui := Gui("+AlwaysOnTop +ToolWindow -Caption", "输入法")
        this.gui.SetFont("s12", "Microsoft YaHei")
        this.gui.AddEdit("r1 w99999 vPreviewText ReadOnly")
        loop 5
            this.gui.AddText("y+5 w99999 vCand" A_Index, "")
        
        this.gui.MarginX := 10
        this.gui.MarginY := 10

        _settingsData := _FileManager._settingsData
        this.SetColor(InputMethodPartType.back, _settingsData.inputMethodGuiBackColor)
        this.SetColor(InputMethodPartType.fore, _settingsData.inputMethodGuiforeColor)
        this.SetColor(InputMethodPartType.text, _settingsData.inputMethodGuiTextColor)
        this.gui.Hide()
        return this.gui
    }

    SetColor(type, color) {
        if (!ColorTools.IsColor(color))
            return
        switch type {
            case InputMethodPartType.back:
                this.gui.BackColor := color
            case InputMethodPartType.fore:
                this.gui["PreviewText"].Opt("+Background" color)
                loop 5 {
                    this.gui["Cand" A_Index].Opt("+Background" color)
                }
            case InputMethodPartType.text:
                this.gui["PreviewText"].Opt("+c" color)
                loop 5 {
                    this.gui["Cand" A_Index].Opt("+c" color)
                }
            default:
        }
    }

    Show(key) {
        if (this._isCompleted) {
            if _FileManager._settingsData.minimalMode {
                this._ShowToolTipAtCaret("完")
            } else {
                this.gui["PreviewText"].Value := "完"
                loop 5
                    this.gui["Cand" A_Index].Text := A_Index ". 完"
                this._ShowAtCaret()
                this._SetWinW(240)
            }
            return
        }

        if (this._inputKeys = "")
            this._inputKeys := key
        else
            this._inputKeys .= "'" key

        this._novelData.pendingCount++
        preview := SubStr(this._novelData.novelText, this._novelData.charIndex, this._novelData.pendingCount)
        preview := StrReplace(StrReplace(preview, "`r", " "), "`n", " ")

        if _FileManager._settingsData.minimalMode {
            this._ShowToolTipAtCaret(preview)
            return
        }

        enCount := 0
        zhCount := 0
        for i, ch in StrSplit(preview) {
            if (Ord(ch) >= 0x4E00 && Ord(ch) <= 0x9FFF
            || Ord(ch) >= 0x3400 && Ord(ch) <= 0x4DBF
            || Ord(ch) >= 0x3000 && Ord(ch) <= 0x303F
            || Ord(ch) >= 0xFF00 && Ord(ch) <= 0xFFEF)
            {
                zhCount++
            }
            else {
                enCount++
            }
        }

        newW := enCount * 8 + zhCount * 16 + 40
        if newW < 200
            newW := 200

        this.gui["PreviewText"].Value := this._inputKeys
        loop 5 
            this.gui["Cand" A_Index].Text := A_Index ". " preview

        this._ShowAtCaret()
        this._SetWinW(newW + 40)
    }

    _ShowAtCaret() {
        if WinExist("ahk_id " this.gui.Hwnd)
            return
        try {
            CaretGetPos(&x, &y)
            this.gui.Show("x" x " y" y " NA w400")
        } catch {
            MouseGetPos(&mx, &my)
            this.gui.Show("x" mx " y" my " NA w400")
        }
    }

    _ShowToolTipAtCaret(text) {
        try {
            CaretGetPos(&x, &y)
            ToolTip(text, x, y + 20)
        } catch {
            MouseGetPos(&mx, &my)
            ToolTip(text, mx, my + 20)
        }
    }

    _SetWinW(w) {
        if w != this._lastWinW {
            this._lastWinW := w
            this.gui.Move(, , w)
            this.gui.GetPos(&x, &y)
            monRight := this._GetMonitorRight(x, y)
            w := w * ScaleFactor
            if x + w > monRight {
                newX := monRight - w
                this.gui.Move(newX/ScaleFactor)
            }
        }
    }

    _GetMonitorRight(x, y) {
        count := MonitorGetCount()
        loop count {
            MonitorGet(A_Index, &mL, &mT, &mR, &mB)
            if x >= mL && x < mR && y >= mT && y < mB
                return mR
        }
        MonitorGet(1, &mL, &mT, &mR, &mB)
        return mR
    }

    Hide() {
        if _FileManager._settingsData.minimalMode
            ToolTip()  ; 清除极简模式的提示工具
        else
            this.gui.Hide()
        this._novelData.pendingCount := 0
        this._inputKeys := ""
        this._lastWinW := 0
    }

    OutputContent() {
        if _FileManager._settingsData.minimalMode
            ToolTip()  ; 清除极简模式的提示工具
        else
            this.gui.Hide()
        if this._novelData.pendingCount = 0 {
            this._inputKeys := ""  ; 清空按键记录
            return
        }
        remain := StrLen(this._novelData.novelText) - this._novelData.charIndex + 1
        toSend := Min(this._novelData.pendingCount, remain)
        if toSend > 0 {
            SendText SubStr(this._novelData.novelText, this._novelData.charIndex, toSend)
            Sleep 100
            this._novelData.charIndex += toSend
        }
        if this._novelData.charIndex > StrLen(this._novelData.novelText) {
            ; 文本已全部输出完成，设置完成标志
            this._isCompleted := true
            this._novelData.charIndex := StrLen(this._novelData.novelText) + 1  ; 保持在结束位置
        } else {
            ; 未完成，清除完成标志
            this._isCompleted := false
        }
        this._novelData.pendingCount := 0
        this._inputKeys := ""  ; 清空按键记录
        _FileManager.SaveProgressFile()
    }

    ResetProgress() {
        this._novelData.charIndex := 1
        this._isCompleted := false
        _FileManager.SaveProgressFile()
    }

    ClearCompletion() {
        this._isCompleted := false
    }
}
