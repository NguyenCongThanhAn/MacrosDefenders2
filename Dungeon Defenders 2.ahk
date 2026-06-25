#Requires AutoHotkey v2.0
#Include "GameButton.ahk"
#MaxThreadsPerHotkey 2
ListLines(0)
ProcessSetPriority("High")

; Định danh chính xác cửa sổ game và trình duyệt của bạn
global gameTarget := "ahk_class LaunchUnrealUWindowsClient ahk_exe DunDefGame.exe"
exitButton := GameButton()
exitButton.add("1280x720", [
    {X: 568, Y: 646, Color: "0x76BDFC"},
    {X: 708, Y: 627, Color: "0x6DA5D1"},
    {X: 626, Y: 637, Color: "0xE5F2FC"}
], 626, 637)
exitButton.add("640x480", [
    {X: 288, Y: 375, Color: "0xF3F9FE"},
    {X: 316, Y: 375, Color: "0xB2D7F6"},
    {X: 354, Y: 371, Color: "0x68A6DB"}
], 354, 371)
replayButton := GameButton()


; Thay đổi thành cửa sổ còn lại
global browserTarget := "ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe" 
global lastUserWindow := 0 ; Biến lưu cửa sổ cũ để trả lại focus

; =========================================================================
; 🔁 HOTKEY KÍCH HOẠT TỔNG (Có thể thay đổi)
; =========================================================================
$F1:: {
    static toggle := false
    static isChoosing := false ; Cờ kiểm tra xem hộp thoại có đang mở không
    global activeMacroLines
    
    ; Nếu hộp thoại đang mở, bấm F1 lần nữa sẽ bị bỏ qua hoàn toàn, không làm gì cả
    if (isChoosing)
        return
        
    toggle := !toggle
    
    if (toggle) {
        SetupDir := A_ScriptDir "\tower_setups"
        if !DirExist(SetupDir)
            DirCreate(SetupDir)
            
        ; Bật cờ khóa phím F1 trước khi mở hộp thoại
        isChoosing := true 
        SelectedFile := FileSelect(3, SetupDir, "Chọn File Macro Xây Tháp", "Setup Files (*.txt; *.ahk)")
        ; Tắt cờ khóa ngay sau khi người dùng chọn xong hoặc bấm Cancel
        isChoosing := false 
        
        if (SelectedFile == "") {
            ToolTip("[Hủy] Chưa chọn file macro", 10, 10)
            SetTimer(() => ToolTip(), -2000)
            toggle := false
            return
        }
        
        activeMacroLines := []
        fileContent := FileRead(SelectedFile)
        
        Loop Parse, fileContent, "`n", "`r" {
            line := Trim(A_LoopField)
            if (line == "" || SubStr(line, 1, 1) == ";" || line == "{" || line == "}")
                continue
            activeMacroLines.Push(line)
        }
        
        SplitPath(SelectedFile, &FileName)
        ToolTip("[Bật] Khởi động: " FileName, 10, 10)
        SoundBeep(800, 200)
        
        SetTimer(MainLoop, 10)
        
    } else {
        ToolTip("[Đang tắt]", 10, 10)
        SetTimer(MainLoop, 0)
        SoundBeep(400, 200)
        ToolTip()
        Reload()
    }
}


; Nút làm mới nhanh kịch bản (F8 - Sẽ thoát toàn bộ hoạt động của script)
$F8:: {
	SoundBeep()
    Reload()
}

; =========================================================================
; + Vòng lặp chính
; =========================================================================
MainLoop() {
    SetTimer(MainLoop, 0) ; Dừng tạm thời để chạy hết chu kỳ ván đấu
    
    if !WinExist(gameTarget) {
        ToolTip("KHÔNG TÌM THẤY CỬA SỔ GAME", 5, 5)
        SetTimer(MainLoop, 1000)
        return
    }

    ; ---------------------------------------------------------------------
    ; 
    ; ---------------------------------------------------------------------
    global lastUserWindow := WinExist("A")
    if (lastUserWindow = WinExist(gameTarget))
        global lastUserWindow := WinExist(browserTarget)

    WinActivate(gameTarget)
    WinWaitActive(gameTarget, , 2)
    Sleep(500)

    ; Bấm phím G một lần bằng lệnh vật lý trước khi vào giai đoạn xây tháp
    ToolTip("=== BẮT ĐẦU TRẬN ===", 5, 5)
    Send("g")
    Sleep(1000) 

    ToolTip("=== TỰ ĐỘNG XÂY THÁP (FOCUS) ===", 5, 5)
	; ---------------------------------------------------------------------
    ; [THAY THẾ EXECBUILDSEQ()] - BỘ PARSER THỰC THI LỆNH ĐỘNG TỪ FILE TEXT
    ; ---------------------------------------------------------------------
    if (activeMacroLines.Length > 0) {
        lineCounter := 0
        
        for line in activeMacroLines {
            lineCounter++
            
            ; Kiểm tra cú pháp xem có đúng dạng Ham(ThamSo) hoặc Ham() không
            if RegExMatch(line, "^([a-zA-Z0-9_]+)\((.*)\)$", &match) {
                funcName := match[1]    ; Lấy tên hàm
                funcParam := Trim(match[2]) ; Lấy tham số
                
                ; Kiểm tra hàm có tồn tại trong file code chính không để tránh bị crash
                if HasFunc(funcName) {
                    targetFunc := %funcName%
                    
                    if (funcParam != "") {
                        if IsInteger(funcParam)
                            funcParam := Integer(funcParam)
                        targetFunc(funcParam) ; Chạy hàm có tham số (ví dụ: down(1000))
                    } else {
                        targetFunc() ; Chạy hàm không tham số (ví dụ: upgrade())
                    }
                } else {
                    ; Tự động bỏ qua dòng nếu tên hàm gõ sai/không tồn tại
                    ToolTip("⚠️ Dòng " lineCounter " bị bỏ qua: Hàm '" funcName "()' chưa định nghĩa!", 5, 5)
                    Sleep(1200)
                }
            } else {
                ; Tự động bỏ qua dòng nếu người dùng sửa file làm sai cú pháp dấu ngoặc
                ToolTip("❌ Dòng " lineCounter " bị bỏ qua vì sai cú pháp: '" line "'", 5, 5)
                Sleep(1200)
            }
        }
    } else {
        ToolTip("⚠️ CẢNH BÁO: Không có lệnh xây tháp nào được nạp!", 5, 5)
        Sleep(2000)
    }
    Sleep(500)

    ; ---------------------------------------------------------------------
    ; TRẢ FOCUS VỀ MÀN HÌNH CŨ CHO BẠN LÀM VIỆC
    ; ---------------------------------------------------------------------
    ToolTip("=== CHẠY NGẦM (DEFOCUS) ===", 5, 5)
    if (lastUserWindow) {
        WinActivate("ahk_id " lastUserWindow)
    } else if WinExist(browserTarget) {
        WinActivate(browserTarget)
    }

    ; Gọi hàm F5 cày ngầm. Hàm này sẽ tự động chạy cho đến khi ván đấu kết thúc.
    Execute_F5_BackgroundSequence()

    ; ---------------------------------------------------------------------
    ; Chờ load ván mới (tăng lên nếu game load chậm)
    ; ---------------------------------------------------------------------
    ToolTip("=== ĐANG CHỜ LOAD MAP MỚI (35s) ===", 5, 5)
    Sleep(35000) 

    ; Kích hoạt lại Timer để tự động bắt đầu một vòng tuần hoàn mới (Quay lại Bước 1)
    SetTimer(MainLoop, 10)
}

; =========================================================================
; Vòng lặp chạy ngầm
; =========================================================================
Execute_F5_BackgroundSequence() {

    Loop {
        
        if (btn := replayButton.check(gameTarget)) {
            ; Luồng nhồi click liên tục của bạn chống lag game kẹt ván
            Loop {
                clickBackground(btn.X, btn.Y)
                Sleep(500)
                
                if (replayButton.check(gameTarget) = false) {
                    break
                }
            }
            
            ToolTip("[Completed] Đã hoàn thành màn chơi", 10, 10)
            SoundBeep(900, 400)
            SetTimer(() => ToolTip(), -2000)
            break ; Thoát khỏi hàm F5 để nhường luồng chạy xuống lệnh chờ load ván mới
        } else if (btn := exitButton.check(gameTarget)) {
        clickBackground(btn.X, btn.Y)
		}
		
        if WinExist(gameTarget) {
            ControlSend("g", , gameTarget)
        }
        Sleep(4000)
    }
}

; =========================================================================
; 🛠️ Các hàm di chuyển, click chuột và macros
; =========================================================================

buildTower(num) {
    Send(String(num)) ; Dùng Send vật lý khi đang focus xây tháp
    Sleep(400)
    if WinExist(gameTarget) {
        WinGetPos(, , &width, &height, gameTarget)
        Click()
    }
    Sleep(400)
}

customClick() {
	Sleep(100)
	Click()
	Sleep(200)
}

upgrade() {
	Send("q")
	Sleep(500)
	Click()
	Sleep(100)
}

moveAxis(directionKey, duration) {
    Send("{" directionKey " Down}")
    Sleep(duration)
    Send("{" directionKey " Up}")
    Sleep(100) 
}

moveDuoAxis(directionKey1, directionKey2, duration) {
	Send("{" directionKey1 " Down}")
	Send("{" directionKey2 " Down}")
	Sleep(duration)
	Send("{" directionKey1 " Up}")
	Send("{" directionKey2 " Up}")
	Sleep(100)
}

up(dur)    	=> moveAxis("w", dur)
down(dur)  	=> moveAxis("s", dur)
left(dur)	=> moveAxis("a", dur)
right(dur)	=> moveAxis("d", dur)
NE(dur)		=> moveDuoAxis("w", "d", dur)
NW(dur)		=> moveDuoAxis("w", "a", dur)
SE(dur)		=> moveDuoAxis("s", "d", dur)
SW(dur)		=> moveDuoAxis("s", "a", dur)

lookStraightDown() {
    DllCall("mouse_event", "UInt", 0x0001, "Int", 0, "Int", 3000, "UInt", 0, "UPtr", 0)
    Sleep(200) 
}


/**
 * Click chuột trong nền (flash chuột đến vị trí click)
 * Trò này lấy vị trí chuột tại thời điểm click làm vị trí click chứ ko phải vị trí click
 */
 
clickBackground(targetX, targetY) {
    targetHWND := WinExist(gameTarget)
    if targetHWND {
        oldMouseMode := A_CoordModeMouse
        CoordMode "Mouse", "Screen"
        
        MouseGetPos(&oldX, &oldY)
        
        pt := Buffer(8, 0)
        NumPut("Int", targetX, pt, 0)
        NumPut("Int", targetY, pt, 4)
        DllCall("ClientToScreen", "Ptr", targetHWND, "Ptr", pt)
        screenX := NumGet(pt, 0, "Int")
        screenY := NumGet(pt, 4, "Int")
        
        DllCall("SetCursorPos", "Int", screenX, "Int", screenY)
        Sleep(20) 
        
        ControlClick(, gameTarget, , "LEFT", 1, "NA Pos")
        Sleep(20)
        
        DllCall("SetCursorPos", "Int", oldX, "Int", oldY)
        
        CoordMode "Mouse", oldMouseMode
    }
}


; Hàm bổ sung để AutoHotkey v2 hiểu được câu lệnh HasFunc()
HasFunc(funcName) {
    try {
        ; Check if the variable name is set in the runtime environment
        if IsSet(%funcName%) {
            ; Check if that variable reference is actually a callable function/object
            return HasMethod(%funcName%)
        }
    }
    return false
}
