#Requires AutoHotkey v2.0
TraySetIcon("shell32.dll", 115)

global macroDir := A_ScriptDir "\tower_setups"
if !DirExist(macroDir)
    DirCreate(macroDir)

global isRecording := false
global lastTick := 0
global macroLines := []
global currentDirection := ""

; 📋 F9: BẮT ĐẦU / DỪNG GHI
F9:: {
    global isRecording, lastTick, macroLines, currentDirection
    isRecording := !isRecording
    
    if (isRecording) {
        macroLines := [] 
        currentDirection := ""
        lastTick := A_TickCount
        ToolTip("🔴 [RECORDING]...", 10, 10)
        SoundBeep(800, 300)
    } else {
        if (currentDirection != "") {
            duration := A_TickCount - lastTick
            macroLines.Push(currentDirection "(" duration ")")
        }
        Send("{w Up}{s Up}{a Up}{d Up}")
        
        ToolTip("⏹️ [STOPPED] Saving...", 10, 10)
        SoundBeep(500, 300)
        
        SaveMacroToFile()
        ToolTip()
    }
}

; 💾 HÀM ĐẶT TÊN VÀ XUẤT FILE TEXT
SaveMacroToFile() {
    global macroLines, macroDir
    
    if (macroLines.Length == 0) {
        MsgBox("Bạn chưa thực hiện thao tác nào để ghi!", "Thông báo", 48)
        return
    }
    
    inputResult := InputBox("Nhập tên cho file macro của bạn (Không gõ đuôi .txt):", "Lưu Kịch Bản Xây Tháp", "w400 h130")
    
    if (inputResult.Result == "Cancel" || inputResult.Value == "") {
        MsgBox("Đã hủy lưu file.", "Thông báo", 64)
        return
    }
    
    fileName := inputResult.Value ".txt"
    fullPath := macroDir "\" fileName
    
    fileContent := ""
    for line in macroLines {
        fileContent .= line "`n"
    }
    
    if FileExist(fullPath) {
        confirm := MsgBox("File '" fileName "' đã tồn tại. Bạn có muốn ghi đè không?", "Trùng tên file", 4)
        if (confirm == "No") {
            SaveMacroToFile()
            return
        }
        FileDelete(fullPath)
    }
    
    FileAppend(fileContent, fullPath, "UTF-8")
    MsgBox("✅ Đã lưu file tại:`n" fullPath, "Thành công", 64)
}

; 🧠 LOGIC CHỐT LỆNH NGẦM
RecordKeyDown(direction) {
    global isRecording, lastTick, currentDirection, macroLines
    if !isRecording
        return
        
    if (currentDirection != "" && currentDirection != direction) {
        duration := A_TickCount - lastTick
        macroLines.Push(currentDirection "(" duration ")")
        lastTick := A_TickCount
        SendMovement(currentDirection, "Up")
    }
    
    if (currentDirection != direction) {
        currentDirection := direction
        SendMovement(direction, "Down")
    }
}

RecordKeyUp(direction) {
    global isRecording, lastTick, currentDirection, macroLines
    if !isRecording
        return
        
    if (currentDirection == direction) {
        duration := A_TickCount - lastTick
        if (duration > 50) { 
            macroLines.Push(direction "(" duration ")")
        }
        currentDirection := ""
        lastTick := A_TickCount
        SendMovement(direction, "Up")
    }
}

; 🏃‍♂️ HÀM GIẢ LẬP GỬI PHÍM DI CHUYỂN CHUẨN VÀO GAME
SendMovement(direction, state) {
    switch direction {
        case "up":    Send("{w " state "}")
        case "down":  Send("{s " state "}")
        case "left":  Send("{a " state "}")
        case "right": Send("{d " state "}")
        case "NW":    Send("{w " state "}{a " state "}")
        case "NE":    Send("{w " state "}{d " state "}")
        case "SW":    Send("{s " state "}{a " state "}")
        case "SE":    Send("{s " state "}{d " state "}")
    }
}

; ⌨️ KHU VỰC OVERRIDE PHÍM VẬT LÝ
#HotIf isRecording

; --- CỤM PHÍM DI CHUYỂN ---
w::RecordKeyDown("up")
w Up::RecordKeyUp("up")
s::RecordKeyDown("down")
s Up::RecordKeyUp("down")
a::RecordKeyDown("left")
a Up::RecordKeyUp("left")
d::RecordKeyDown("right")
d Up::RecordKeyUp("right")
e::RecordKeyDown("NE")
e Up::RecordKeyUp("NE")
q::RecordKeyDown("NW")
q Up::RecordKeyUp("NW")
c::RecordKeyDown("SE")
c Up::RecordKeyUp("SE")
z::RecordKeyDown("SW")
z Up::RecordKeyUp("SW")

; --- CỤM PHÍM THAO TÁC CHỌN TRỤ (4 -> 8) ---
4:: {
	buildNonRotateTower(4)
    RecordKeyDown("")
    currentDirection := ""
    macroLines.Push("buildTower(4)")
}
5:: {
	buildNonRotateTower(5)
    RecordKeyDown("")
    currentDirection := ""
    macroLines.Push("buildTower(5)")
}
6:: {
	buildNonRotateTower(6)
    RecordKeyDown("")
    currentDirection := ""
    macroLines.Push("buildTower(6)")
}
7:: {
	buildNonRotateTower(7)
    RecordKeyDown("")
    currentDirection := ""
    macroLines.Push("buildTower(7)")
}
8:: {
	buildNonRotateTower(8)
    RecordKeyDown("")
    currentDirection := ""
    macroLines.Push("buildTower(8)")
}

; --- CÁC HÀM PHỤ TRỢ ---
x:: {
	lookStraightDown()
    RecordKeyDown("") 
    currentDirection := "" 
    macroLines.Push("lookStraightDown()")
}

r:: {
	upgrade()
    RecordKeyDown("")
    currentDirection := ""
    macroLines.Push("upgrade()")
}

#HotIf

; --- CÁC HÀM CHỨC NĂNG (VIẾT SẴN ĐỂ DÙNG TRONG CÁC CẬP NHẬT SAU, KHÔNG LƯỢC BỎ)
buildNonRotateTower(num) {
    Send(String(num))
    Sleep(414)
    Click()
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
