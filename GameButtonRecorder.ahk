#Requires AutoHotkey v2.0
TraySetIcon("shell32.dll", 44)

; --- CẤU HÌNH ---
gameTarget := "ahk_class LaunchUnrealUWindowsClient ahk_exe DunDefGame.exe" ; <<-- Thay bằng tên game của bạn

; Mảng lưu danh sách tọa độ bạn đã đánh dấu
SavedCoords := []

; 📌 PHÍM TẮT F1: CHỈ GHI NHỚ TỌA ĐỘ (CHƯA ĐỌC MÀU)
F1:: {
    global gameTarget, SavedCoords
    
    if !WinExist(gameTarget) {
        ToolTip("❌ Không tìm thấy game!")
        SetTimer(() => ToolTip(), -2000)
        return
    }
    
    ; Lấy tọa độ chuột hiện tại theo lòng cửa sổ game
    oldMode := A_CoordModeMouse
    CoordMode "Mouse", "Client"
    MouseGetPos(&mouseX, &mouseY)
    CoordMode "Mouse", oldMode
    
    ; Chỉ lưu tọa độ X, Y vào mảng tạm
    SavedCoords.Push({X: mouseX, Y: mouseY})
    
    ToolTip("📌 Đã ghi nhớ tọa độ điểm " SavedCoords.Length "`n[X: " mouseX " | Y: " mouseY "]`n(Hãy né chuột ra trước khi bấm F2)")
    SetTimer(() => ToolTip(), -2000)
}

; 📋 PHÍM TẮT F2: THỰC SỰ ĐỌC MÀU TẠI CÁC TỌA ĐỘ ➔ FORMAT CODE ➔ COPY
F2:: {
    global gameTarget, SavedCoords
    
    targetHWND := WinExist(gameTarget)
    if !targetHWND {
        ToolTip("❌ Không tìm thấy game!")
        SetTimer(() => ToolTip(), -2000)
        return
    }
    
    if (SavedCoords.Length == 0) {
        ToolTip("⚠ Chưa có tọa độ nào! Hãy hơ chuột và nhấn F1 trước.")
        SetTimer(() => ToolTip(), -2000)
        return
    }
    
    ; Đo độ phân giải thực tế của game
    WinGetClientPos(, , &w, &h, "ahk_id " targetHWND)
    currentRes := w "x" h
    
    try {
        ; Mở kết nối đồ họa lấy màu 1 lần duy nhất cho tất cả các điểm (tăng tốc độ)
        hdc := DllCall("GetDC", "Ptr", targetHWND, "Ptr") 
        
        ; Dựng chuỗi kết quả chuẩn định dạng cho hàm GameButton.add()
        output := 'btnName.add("' currentRes '", [`n'
        
        for index, coord in SavedCoords {
            ; Bây giờ mới thực sự đọc màu tại tọa độ cũ, mặc kệ chuột của bạn đang ở đâu
            bgrColor := DllCall("Gdi32\GetPixel", "Ptr", hdc, "Int", coord.X, "Int", coord.Y, "UInt")
            
            if (bgrColor == 0xFFFFFFFF) {
                DllCall("ReleaseDC", "Ptr", targetHWND, "Ptr", hdc)
                MsgBox("Lỗi lấy màu tại điểm " index " (Có thể cửa sổ bị che hoặc thu nhỏ).")
                return
            }
            
            ; Đổi BGR sang RGB
            r := bgrColor & 0xFF, g := (bgrColor >> 8) & 0xFF, b := (bgrColor >> 16) & 0xFF
            hexColor := "0x" Format("{:06X}", (r << 16) | (g << 8) | b)
            
            ; Nối chuỗi code
            output .= '    {X: ' coord.X ', Y: ' coord.Y ', Color: "' hexColor '"}'
            if (index < SavedCoords.Length)
                output .= ",`n"
            else
                output .= "`n"
        }
        
        DllCall("ReleaseDC", "Ptr", targetHWND, "Ptr", hdc) 
        
        ; Lấy tọa độ cuối cùng làm điểm click mặc định
        lastPoint := SavedCoords[SavedCoords.Length]
        output .= '], ' lastPoint.X ', ' lastPoint.Y ')'
        
        ; Nạp vào Clipboard
        A_Clipboard := output
        
        ; Reset mảng tọa độ để chuẩn bị lấy nút tiếp theo
        SavedCoords := []
        
        MsgBox("Đã quét màu thành công và copy vào Clipboard!`n`n" output, "Thành công", 64)
        
    } catch {
        ToolTip("❌ Có lỗi xảy ra khi đọc đồ họa!")
        SetTimer(() => ToolTip(), -2000)
    }
}

; Phím tắt phụ F3 để xóa nhanh dữ liệu đang làm dở nếu bấm nhầm
F3:: {
    global SavedCoords := []
    ToolTip("♻ Đã xóa các điểm đang chọn dở!")
    SetTimer(() => ToolTip(), -2000)
}


$F8:: {
	Reload()
}
