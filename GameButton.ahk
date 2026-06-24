#Requires AutoHotkey v2.0

class GameButton {
    data := Map()

    ; Hàm nạp dữ liệu (Giữ nguyên)
    add(res, checkPoints, clickX, clickY) {
        this.data[res] := {
            Points: checkPoints,
            X: clickX,
            Y: clickY
        }
    }

    ; Hàm lấy dữ liệu (Giữ nguyên)
    get(res) => this.data.Has(res) ? this.data[res] : ""

    /**
     * Hàm tự động kiểm tra tất cả các điểm màu của nút dựa vào gameTarget
     * @param gameTarget Tiêu đề hoặc ahk_exe của game
     * @param variation Độ lệch màu cho phép (mặc định là 10, chỉnh về 0 nếu muốn khớp tuyệt đối)
     * @returns Trả về Object dữ liệu {X, Y} nếu TẤT CẢ điểm khớp màu, ngược lại trả về false
     */
    check(gameTarget, variation := 10) {
        ; 1. Lấy HWND và đo độ phân giải thực tế của game
        targetHWND := WinExist(gameTarget)
        if !targetHWND
            return false
            
        WinGetClientPos(, , &w, &h, "ahk_id " targetHWND)
        currentRes := w "x" h
        
        ; 2. Kiểm tra xem độ phân giải hiện tại của game đã được viết code chưa
        if !this.data.Has(currentRes)
            return false
            
        b := this.data[currentRes]
        
        ; 3. Quét qua tất cả các điểm màu trong mảng
        for point in b.Points {
            ; Gọi hàm lấy màu ngầm của bạn (hàm này phải nằm ở file chính hoặc được khai báo)
            actualColorHex := getBackgroundPixel(targetHWND, point.X, point.Y)
            
            ; Kiểm tra trùng khớp màu (có tính sai số variation)
            c1 := Integer(point.Color), c2 := Integer(actualColorHex)
            r1 := (c1 >> 16) & 0xFF, g1 := (c1 >> 8) & 0xFF, b1 := c1 & 0xFF
            r2 := (c2 >> 16) & 0xFF, g2 := (c2 >> 8) & 0xFF, b2 := c2 & 0xFF
            
            ; Nếu chỉ cần 1 điểm không khớp, nút này chưa xuất hiện -> Hủy bỏ ngay
            if (Abs(r1 - r2) > variation || Abs(g1 - g2) > variation || Abs(b1 - b2) > variation)
                return false
        }
        
        ; 4. Nếu vượt qua tất cả các điểm check -> Trả về chính Object chứa tọa độ click (X, Y)
        return b
    }
}

getBackgroundPixel(gameTarget, targetX, targetY) {
    targetHWND := WinExist(gameTarget)
    if targetHWND {
        try {
            hdc := DllCall("GetDC", "Ptr", targetHWND, "Ptr") 
            bgrColor := DllCall("Gdi32\GetPixel", "Ptr", hdc, "Int", targetX, "Int", targetY, "UInt")
            DllCall("ReleaseDC", "Ptr", targetHWND, "Ptr", hdc) 
            
            if (bgrColor == 0xFFFFFFFF)
                return "0x000000"

            r := bgrColor & 0xFF, g := (bgrColor >> 8) & 0xFF, b := (bgrColor >> 16) & 0xFF
            return "0x" Format("{:06X}", (r << 16) | (g << 8) | b)
        } catch {
            return "0x000000"
        }
    }
    return "0x000000"
}

