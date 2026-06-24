#Requires AutoHotkey v2.0
#SingleInstance Force

; =========================================================================
; 🎮 THIẾT LẬP CÁC BIẾN TOÀN CỤC CHẠY NỀN
; =========================================================================
global gameTarget := "ahk_class LaunchUnrealUWindowsClient ahk_exe DunDefGame.exe"
global actionLog := []
global currentDir := ""
global dirStartTime := 0
global isRecording := false

TrayTip("F10: Ghi | Numpad5: Chúi Camera | F11: Copy", "DD2 Numpad Recorder", 1)

; =========================================================================
; 🧠 HÀM ĐIỀU KHIỂN BỘ GHI (RECORD CONTROLLER)
; =========================================================================

$F10:: {
    global actionLog := []
    global currentDir := ""
    global dirStartTime := 0
    global isRecording := true
    SoundBeep(800, 300)
    ToolTip("🔴 ĐANG GHI BẰNG NUMPAD... (Numpad5 để chúi camera xuống đất)", 10, 10)
}

$F11:: {
    global isRecording := false
    SoundBeep(500, 300)
    ToolTip()
    
    if (currentDir != "") {
        duration := A_TickCount - dirStartTime
        if (duration > 40)
            actionLog.Push({type: "move", dir: currentDir, dur: duration})
    }
    
    if (actionLog.Length = 0) {
        MsgBox("Chưa ghi nhận thao tác nào! Hãy bấm F10 trước.", "Thông báo", 48)
        return
    }
    
    ; BIÊN DỊCH DỮ LIỆU SẠCH (BỎ KHOẢNG TRỐNG) THEO HÀM CỦA BẠN
    outputString := "; === ĐOẠN CODE F7 ĐƯỢC TỐI ƯU HÓA TỪ NUMPAD ===`n`n"
    
    for action in actionLog {
        if (action.type == "look") {
            outputString .= "lookStraightDown()`n"
        } else if (action.type == "move") {
            outputString .= action.dir . "(" . action.dur . ")`n"
        } else if (action.type == "build") {
            outputString .= "buildTower(" . action.num . ")`n"
        }else if (action.type == "click") {
            outputString .= "customClick()`n"
        } else if (action.type == "upgrade") {
            outputString .= "upgrade()`n"
        }
    }
    
    ; Găm thẳng chuỗi kết quả vào Clipboard hệ thống của bạn
    A_Clipboard := outputString
    
    fileName := A_ScriptDir . "\DD2_Numpad_Record.txt"
    if FileExist(fileName)
        FileDelete(fileName)
    FileAppend(outputString, fileName, "UTF-8")
    
    MsgBox("Đã lưu vào Clipboard thành công!`nGiờ bạn chỉ cần mở file F7 ra và bấm Ctrl + V để dán.", "Thành công", 64)
}

; =========================================================================
; ⌨️ HOTKEYS BÀN PHÍM SỐ (NUMPAD DIRECTIONAL HOTKEYS)
; =========================================================================

; --- PHÍM TRUNG TÂM NUMPAD 5: TỰ ĐỘNG CHÚI CAMERA XUỐNG ĐẤT VÀ GHI FILE ---
*Numpad5:: TriggerLookDown()

; --- 8 HƯỚNG DI CHUYỂN VẬT LÝ VÀ ĐO THỜI GIAN REALTIME ---
*Numpad8::  TriggerMoveDown("up", "w")
*Numpad8 Up:: TriggerMoveUp("up", "w")

*Numpad2::  TriggerMoveDown("down", "s")
*Numpad2 Up:: TriggerMoveUp("down", "s")

*Numpad4::  TriggerMoveDown("left", "a")
*Numpad4 Up:: TriggerMoveUp("left", "a")

*Numpad6::  TriggerMoveDown("right", "d")
*Numpad6 Up:: TriggerMoveUp("right", "d")

*Numpad9::  TriggerDuoMoveDown("NE", "w", "d")
*Numpad9 Up:: TriggerDuoMoveUp("NE", "w", "d")

*Numpad7::  TriggerDuoMoveDown("NW", "w", "a")
*Numpad7 Up:: TriggerDuoMoveUp("NW", "w", "a")

*Numpad3::  TriggerDuoMoveDown("SE", "s", "d")
*Numpad3 Up:: TriggerDuoMoveUp("SE", "s", "d")

*Numpad1::  TriggerDuoMoveDown("SW", "s", "a")
*Numpad1 Up:: TriggerDuoMoveUp("SW", "s", "a")

; --- 3 PHÍM CHỨC NĂNG THAO TÁC XÂY DỰNG / NÂNG CẤP ---
*Numpad0::     TriggerBuildClick(4)
*NumpadDot::   TriggerBuildClick(5)
*NumpadEnter:: TriggerCustomClick()
*NumpadAdd::   TriggerUpgradeClick()ssd

; =========================================================================
; 🛠️ ENGINE XỬ LÝ LOGIC LOG VÀ ĐIỀU KHIỂN NHÂN VẬT REALTIME
; =========================================================================

TriggerLookDown() {
    lookStraightDown() ; Quay camera thực tế trong game
    if (!isRecording) 
        return ""
    FinalizeLastAction()
    actionLog.Push({type: "look"})
}

TriggerMoveDown(dirName, gameKey) {
    if (!isRecording) 
        return ""
    global currentDir, dirStartTime
    
    if (currentDir != dirName) {
        FinalizeLastAction()
        currentDir := dirName
        dirStartTime := A_TickCount
        Send("{" gameKey " Down}")
    }
}

TriggerMoveUp(dirName, gameKey) {
    Send("{" gameKey " Up}")
    if (!isRecording) 
        return ""
    global currentDir
    
    if (currentDir == dirName) {
        FinalizeLastAction()
    }
}

TriggerDuoMoveDown(dirName, gameKey1, gameKey2) {
    if (!isRecording) 
        return ""
    global currentDir, dirStartTime
    
    if (currentDir != dirName) {
        FinalizeLastAction()
        currentDir := dirName
        dirStartTime := A_TickCount
        Send("{" gameKey1 " Down}{" gameKey2 " Down}")
    }
}

TriggerDuoMoveUp(dirName, gameKey1, gameKey2) {
    Send("{" gameKey1 " Up}{" gameKey2 " Up}")
    if (!isRecording) 
        return ""
    global currentDir
    
    if (currentDir == dirName) {
        FinalizeLastAction()
    }
}

TriggerCustomClick() {
    click()
    if (!isRecording) 
        return ""
    FinalizeLastAction()
    actionLog.Push({type: "click"})
}

TriggerBuildClick(towerNum) {
    buildNonRotateTower(towerNum)
    if (!isRecording) 
        return ""
    FinalizeLastAction()
    actionLog.Push({type: "build", num: towerNum})
}

TriggerUpgradeClick() {
    upgrade()
    if (!isRecording) 
        return ""
    FinalizeLastAction()
    actionLog.Push({type: "upgrade"})
}

FinalizeLastAction() {
    global currentDir, dirStartTime, actionLog
    if (currentDir != "") {
        duration := A_TickCount - dirStartTime
        if (duration > 40) {
            actionLog.Push({type: "move", dir: currentDir, dur: duration})
        }
        currentDir := ""
    }
}

; =========================================================================
; 🎮 CÁC HÀM THAO TÁC GỐC CỦA BẠN (GIỮ NGUYÊN ĐỂ CORE ENGINE THỰC THI)
; =========================================================================

buildNonRotateTower(num) {
    Send(String(num))
    Sleep(414)
    if WinExist(gameTarget) {
        WinGetPos(, , &width, &height, gameTarget)
        Click()
    }
    Sleep(400)
}

upgrade() {
	Send("q")
	Sleep(500)
	Click()
	Sleep(10)
}

fly() {
	Send("{Space down}")
    Sleep(50)
	Send("{Space up}")
	Sleep(100)
	Send("{Space down}")
    Sleep(1000)
	Send("{Space up}")
}

unfly() {
	Send("Space")
}

lookStraightDown() {
    DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", 3000, "UInt", 0, "UPtr", 0)
    Sleep(200) 
}
