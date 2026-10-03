# Quản lý Tài liệu Học tập

Ứng dụng Flutter lưu tài liệu học tập cục bộ bằng SQLite/Drift. Package: `study_docs`.

## Chức năng

- Thêm, sửa và xóa tài liệu bằng cách vuốt ngang.
- Thêm, sửa và xóa tài liệu bằng cách vuốt ngang.
- Mỗi tài liệu có thể lưu nhiều file đính kèm (tối đa 10 MB/file) trong SQLite.
Danh sách tài liệu và file được phát qua Drift `watch()` stream. Truy vấn danh sách
chỉ lấy metadata và số lượng file; Blob chỉ được nạp khi tải file.
- Tìm theo tiêu đề, môn học hoặc ghi chú; lọc theo loại.
- Dữ liệu gồm UUID, tiêu đề, loại, môn học, ghi chú tùy chọn và ngày tạo.
- Xác thực tiêu đề/môn học không rỗng và loại tài liệu hợp lệ.

## Kiến trúc

- `data/database`: schema Drift tập trung, schema version và truy vấn reactive.
- `data/repositories`: chuyển đổi giữa hàng SQLite và model miền.
- `domain/services`: xác thực dữ liệu và tạo UUID.
- `presentation`: giao diện và controller Provider.
- `core/utils`: enum loại tài liệu và hàm định dạng dùng chung.

Danh sách được phát qua Drift `watch()` stream và hiển thị bằng `StreamBuilder`.

## Chạy

```shell
flutter pub get
dart run build_runner build
flutter run
```

Chạy kiểm tra bằng `flutter analyze` và `flutter test`.
