#Requires AutoHotkey v2.0
#MaxThreadsPerHotkey 2
ListLines(0)
ProcessSetPriority("High")

; Định danh chính xác cửa sổ game dựa trên chuỗi thông tin của bạn
global gameTarget := "ahk_class LaunchUnrealUWindowsClient ahk_exe DunDefGame.exe"

; =========================================================================
; 🛠️ HÀM HỖ TRỢ CHẠY NGẦM THUẦN TÚY (BACKGROUND UTILITIES)
; =========================================================================

/**
 * Sends a keyboard stroke directly to the game process in the background.
 */
sendBackgroundKey(keyState) {
    if WinExist(gameTarget) {
        ControlSend(keyState, , gameTarget)
    }
}

/**
 * Simulates a mouse customClick at a specific X/Y coordinate without activating the window.
 * @param {Integer} targetX - X coordinate relative to the game window client area.
 * @param {Integer} targetY - Y coordinate relative to the game window client area.
 */
/**
 * ĐÃ SỬA THEO LOGIC CỦA BẠN: 
 * 1. Lấy tọa độ cũ con trỏ đổi sang Screen
 * 2. Đổi vị trí Replay (X, Y) sang Screen
 * 3. Di chuyển con trỏ thật đến vị trí nút trên Screen
 * 4. ControlClick (gửi lệnh customClick ngầm vào game tại vị trí đó)
 * 5. Di chuyển con trỏ về vị trí cũ trên Chrome
 */
customClickBackground(targetX, targetY) {
    targetHWND := WinExist(gameTarget)
    if targetHWND {
        ; Ép hệ tọa độ chuột tính theo Screen vật lý để không bị phụ thuộc vào Chrome/Game
        oldMouseMode := A_CoordModeMouse
        CoordMode "Mouse", "Screen"
        
        ; BƯỚC 1: Lấy tọa độ cũ của con trỏ chuột thật (định dạng Screen)
        MouseGetPos(&oldX, &oldY)
        
        ; BƯỚC 2: Đổi vị trí Replay (targetX, targetY) nội bộ của game sang hệ Screen
        pt := Buffer(8, 0)
        NumPut("Int", targetX, pt, 0)
        NumPut("Int", targetY, pt, 4)
        DllCall("ClientToScreen", "Ptr", targetHWND, "Ptr", pt)
        screenX := NumGet(pt, 0, "Int")
        screenY := NumGet(pt, 4, "Int")
        
        ; BƯỚC 3: Di chuyển con trỏ thật đến đúng vị trí nút Replay trên màn hình
        ; (Số 0 ở cuối nghĩa là di chuyển siêu tốc với tốc độ nhanh nhất)
        DllCall("SetCursorPos", "Int", screenX, "Int", screenY)
        Sleep(20) ; Chờ 20ms để game nhận diện con chuột thật đã nằm trên nút
        
        ; BƯỚC 4: ControlClick ngầm vào game
        ; (Vì con chuột thật đã nằm đúng vị trí nút, game bốc tọa độ chuột thật để customClick sẽ trúng 100%)
        ControlClick("X" targetX " Y" targetY, gameTarget, , "LEFT", 1, "NA")
        Sleep(20)
        
        ; BƯỚC 5: Di chuyển con trỏ chuột vật lý về lại vị trí cũ trên Chrome ngay lập tức
        DllCall("SetCursorPos", "Int", oldX, "Int", oldY)
        
        ; Khôi phục lại trạng thái hệ tọa độ mặc định của script
        CoordMode "Mouse", oldMouseMode
    }
}


/**
 * ĐÃ FIX: Hàm đọc màu ngầm xuyên thấu bám theo cửa sổ qua cơ chế GetDC đồ họa
 */
getBackgroundPixelColor(targetX, targetY) {
    targetHWND := WinExist(gameTarget)
    if targetHWND {
        try {
            hdc := DllCall("GetDC", "Ptr", targetHWND, "Ptr") 
            bgrColor := DllCall("Gdi32\GetPixel", "Ptr", hdc, "Int", targetX, "Int", targetY, "UInt")
            DllCall("ReleaseDC", "Ptr", targetHWND, "Ptr", hdc) 
            
            if (bgrColor == 0xFFFFFFFF)
                return "0x000000"

            r := bgrColor & 0xFF, g := (bgrColor >> 8) & 0xFF, b := (bgrColor >> 16) & 0xFF
            return "0x" . Format("{:06X}", (r << 16) | (g << 8) | b)
        } catch {
            return "0x000000"
        }
    }
    return "0x000000"
}

; =========================================================================
; 🎮 CÁC HÀM XÂY THÁP VÀ DI CHUYỂN (ĐÃ FIX PHÍM VẬT LÝ KHI FOCUS)
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

; =========================================================================
; 🔁 HOTKEYS TRIGGER THỦ CÔNG
; =========================================================================

; NÚT F5: Bật ngầm hoàn toàn, bấm xong Alt-Tab qua Chrome lướt web, game tự cày tự Replay
$F5:: {
    static toggle := false
	static shard_streak := 1
    toggle := !toggle
    
    exitClickX := 637, exitClickY := 637
    
    ; >> Cấu hình Tọa độ nút Replay Map của bạn
    replayCheckX1 := 819, replayCheckY1 := 530, replayTargetColor1 := "0x4D4D4D"
    replayCheckX2 := 686, replayCheckY2 := 249, replayTargetColor2 := "0x2E2E2E"
    replayButtonX := 827, replayButtonY := 638
	
	; >> Roller Regconigtion
    rollerCheckX1 := 400, rollerCheckY1 := 50, rollerTargetColor1 := "0xC6E6CE"
	rollerCheckX2 := 375, rollerCheckY2 := 60, rollerTargetColor2 := "0xA0C5B8"
    if (toggle) {
        ToolTip("[Bật] Macro cày ngầm F5..." . shard_streak, 10, 10)
        SoundBeep(800, 200)
    } else {
        ToolTip("[Tắt] Đã dừng cày ngầm.", 10, 10)
        SetTimer(() => ToolTip(), -1500)
        SoundBeep(400, 200)
    }
    
    while toggle {

        currentReplay1 := getBackgroundPixelColor(replayCheckX1, replayCheckY1)
        currentReplay2 := getBackgroundPixelColor(replayCheckX2, replayCheckY2)
        
		currentRoller1 := getBackgroundPixelColor(rollerCheckX1, rollerCheckY1)
		currentRoller2 := getBackgroundPixelColor(rollerCheckX2, rollerCheckY2)
		
		if (currentRoller1 = rollerTargetColor1 and currentRoller2 = rollerTargetColor2) {
			Loop {
				SoundBeep(1000, 500)
				Sleep(2000)
				currentRoller1 := getBackgroundPixelColor(rollerCheckX1, rollerCheckY1)
				currentRoller2 := getBackgroundPixelColor(rollerCheckX2, rollerCheckY2)
				if !(currentRoller1 = rollerTargetColor1 and currentRoller2 = rollerTargetColor2) {
					break
				}
			}
		}
        if (currentReplay1 = replayTargetColor1 and currentReplay2 = replayTargetColor2) {
            Loop {
            customClickBackground(replayButtonX, replayButtonY)
            Sleep(500)

            currentReplay1 := getBackgroundPixelColor(replayCheckX1, replayCheckY1)
            currentReplay2 := getBackgroundPixelColor(replayCheckX2, replayCheckY2)

				if !(currentReplay1 = replayTargetColor1 and currentReplay2 = replayTargetColor2) {
					break
				}
			}
			shard_streak++
			ToolTip("[Bật] Macro cày ngầm F5..." . shard_streak, 10, 10)
			SoundBeep(800, 200)
            

			Sleep(75000)
        } else if (shard_streak > 3) 
			customClickBackground(exitClickX, exitClickY)

        sendBackgroundKey("g")
        Sleep(4000)
    }
}

; NÚT F7: Bấm thủ công khi đang mở game (Focus) để nhân vật tự động chạy đi xây tháp mượt mà 100%
$F7:: {
    if !WinActive(gameTarget) ; Chỉ cho chạy chuỗi nếu cửa sổ game đang Active thực tế trước mắt bạn
        return

; === ĐOẠN CODE F7 ĐƯỢC TỐI ƯU HÓA TỪ NUMPAD ===

lookStraightDown()
down(1000)
up(1781)
NE(1265)
NW(2000)
NE(300)
buildTower(4)
upgrade()
down(94)
NW(306)
buildTower(4)
upgrade()
down(469)
buildTower(5)
NW(281)
buildTower(5)
NW(1016)
buildTower(4)
upgrade()
SE(422)
buildTower(4)
upgrade()
SW(297)
buildTower(5)
upgrade()
NW(281)
buildTower(5)
down(1110)
SE(3060)
left(4000)
NE(156)
left(2547)
SW(1343)
NE(485)
buildTower(4)
upgrade()
right(891)
buildTower(5)
upgrade()
up(328)
buildTower(5)
upgrade()
down(984)
left(406)
down(187)
buildTower(4)
upgrade()




}

; Nút làm mới kịch bản (F8)
$F8:: {
    TrayTip("Đang tải lại script...", "Macro DD2", 1)
    Sleep(500)
    Reload()
}

$F6:: {
    shard_streak := true
}