# MacrosDefenders2

Some handmade Macros for DD2

## Tải về

Bước 1: Tải AutoHotKey v2.
https://www.autohotkey.com/

Bước 2: Tải file zip của project này về và giải nén

# Tính năng

- Cày game trong nền
- Tạo instruction xây tháp
- Xây tháp tự động bằng script
- Tự động nhấn chơi lại
- Tương thích với nhiều dộ phân giải màn hình

## AutoGrinding

Gồm 2 file là `DD2AutoFarm.ahk` và `Dungeon Defenders 2.ahk`

- `DD2AutoFarm.ahk`: Gồm các macros riêng lẻ trong các giai đoạn khi treo máy.
- `Dungeon Defenders 2.ahk`: Gộp toàn bộ macros thành 1 vòng lặp treo máy hoàn toàn, kích hoạt và tắt bằng phím `F1`.

Lưu ý: Cần tắt chức năng Persistent Tower Interaction trong Mục Gameplay của cài đặt game

## Build Script

Để sử dụng Chức năng tự động xây tháp cần chọn 1 build script

Để tạo build script cần mở các file.ahk Record hoặc Recorder

Các script tạo ra dưới dạng văn bản định dạng .txt lưu trong folder `tower_setups/`

### Instruction Recorder (Keyboard).ahk

Dành cho người dùng không có bàn phím số

Keyboard Layout
|||||||||F9|
| :---:| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
|3|4|5|6|7|8||||
| Q | W | E | R || `↖` | `↑` | `↗` | ▲  |
| A | S | D | F |⇔| `←`  | `↓` | `→` |  |
| Z | X | C |   || `↙` | `👁`| `↘` |
- `#` : Xây trụ với số tương ứng
- `▲` : Nâng cấp trụ
- `👁` : Nhìn thẳng xuống đất
- F9 : Bật/lưu máy ghi
