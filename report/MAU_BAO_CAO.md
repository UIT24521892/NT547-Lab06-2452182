# NT547 - LAB 06 - BÁO CÁO (TỰ ĐIỀN)

**MSSV:** 2452182  | **Họ tên:** Hồ Lê Anh Trường | **Lớp:** ...
**Session code tự sinh:** SC-C56214 | **Tên contract:** TipJar_2182
**Solidity / Slither:** 0.8.24 / 0.11.6 | **Ngày hoàn thành:** ...
**URL GitHub repository:** ...

## 1. Static scan (2,0 điểm)

- Lệnh raw: `python tools/scan.py --mode raw --tag before`
- Số lượng finding raw từ `evidence/before_raw/summary.json`:
  - High: 3; Medium: 2; Low: 2; Informational: 5; Optimization: 0. Tổng: 12 findings.
- Chạy configured: `python tools/scan.py --mode configured --tag before`
- Kết quả configured: High: 3; Medium: 2; Low: 0; Informational: 0; Optimization: 0. Tổng: 5 findings.
- So sánh raw/configured: cấu hình loại 2 Low và 5 Informational; giữ nguyên cả 3 High và 2 Medium. Cấu hình cũng loại detector `solc-version`, nhưng detector này không xuất hiện trong baseline raw nên không tạo chênh lệch ở lần chạy này. Đây là thay đổi bộ lọc hiển thị, chưa phải sửa mã.
- 3 detector **khác tên** được chọn từ kết quả raw: `weak-prng`, `controlled-delegatecall`, `suicidal`. Các ID F01–F03 dưới đây do báo cáo quy ước, tương ứng ba mục đầu trong danh sách detectors của baseline raw.

| ID finding | Detector | Impact | Confidence | Source (file:dòng) | Luồng dữ liệu: đầu vào -> thao tác -> tác hại |
|---|---|---|---|---|---|
| F01 | weak-prng | High | Medium | AuditTarget.sol:37, hàm uiDay() | block.timestamp -> chia lấy ngày và modulo 7 -> trả về chỉ số ngày. Slither nhận diện dạng phép tính giống PRNG, nhưng hàm chỉ trả dữ liệu view; kết quả không được dùng để cấp quyền hoặc chi tiền trong source hiện tại. Cần triage theo ngữ cảnh. |
| F02 | controlled-delegatecall | High | Medium | AuditTarget.sol:57, hàm execute(address,bytes) | Caller bất kỳ cung cấp target và data -> contract delegatecall tới mã do caller chọn -> mã đích chạy trong ngữ cảnh storage của TipJar_2182, có thể ghi đè owner và chiếm quyền. |
| F03 | suicidal | High | High | AuditTarget.sol:53, hàm sunset() | Caller bất kỳ -> gọi sunset không có kiểm tra quyền -> selfdestruct chuyển toàn bộ ETH tới msg.sender. Với EVM áp dụng EIP-6780, ngoài giao dịch tạo contract, code/storage không bị xóa nhưng ETH vẫn có thể bị rút trái phép. |

- Exit code local là 0 vì script dùng `--fail-none` để thu findings; đây không phải kết luận hợp đồng an toàn. Bằng chứng: `evidence/before_raw/` và `evidence/before_configured/`, mỗi thư mục có JSON, CSV, summary và log lệnh.

## 2. Triage và sửa lỗi (2,5 điểm)

Đọc toàn bộ AuditTarget.sol: nhận diện **4 mẫu lỗi thật + 2 đoạn cần đánh giá ngữ cảnh**,
kể cả khi Slither không hiển thị đủ 6 cảnh báo. Với mẫu không có detector,
ghi “Manual review / Not reported”, KHÔNG sửa slither.json hoặc tạo finding giả.

| Detector + vị trí | TP / FP / Chưa kết luận | Bằng chứng kiểm soát/khả năng khai thác | Biện pháp (Fix / Accept có lý do) | Sau sửa |
|---|---|---|---|---|
| | | | | |
| | | | | |
| | | | | |
| | | | | |
| | | | | |
| | | | | |

- Mô tả ít nhất 01 kịch bản khai thác TP: người gọi -> điều kiện -> call/state -> hậu quả: ...
- Phân tích 01 finding có severity cao nhưng risk thực tế không tương ứng: ...
- Dẫn bằng chứng `git diff`, scan before/after và giải thích cảnh báo còn lại: ...
- Lý do của mọi `slither-disable-next-line`: ... (tên detector, đúng vị trí, kiểm soát bù trừ).

## 3. Kiến trúc / Inheritance (1,5 điểm)

- Lệnh printer đã chạy: ...
- Ảnh `evidence/architecture/inheritance.png` (hoặc .dot, nếu Graphviz chưa có): ...
- Access control nằm ở ...; logic số dư nằm ở ...; contract triển khai nằm ở ...
- Giải thích 3–5 câu điểm audit cần bắt đầu: ...

## 4. Red -> Green CI (2,5 điểm)

| Phase | Commit (full/short SHA) | Run URL | Kết quả | Detector khiến RED / lý do GREEN |
|---|---|---|---|---|
| Baseline vulnerable | | | RED | |
| Patched | | | GREEN | |

- So sánh local `--fail-none` (thu thập findings) với CI `fail-on: medium`: ...
- `exclude_low/informational` thay đổi kết quả hiển thị ra sao: ...

## 5. Mutation RED -> GREEN (1,5 điểm)

- Mutation một dòng: `require(msg.sender == owner, "not owner")` -> `require(tx.origin == owner, "not owner")` trong `modifier onlyOwner`.
- Detector kỳ vọng: `tx-origin` (mức Medium); xác nhận của em từ CI: ...

| Phase | Commit SHA | Run URL | Kết quả |
|---|---|---|---|
| Mutation | | | RED |
| Revert mutation | | | GREEN |

- Giải thích sự thay đổi về nguồn định danh/authorization: ...

## 6. Bằng chứng, tự kiểm

- [ ] `AuditTarget.sol`, `lab_identity.json`
- [ ] `evidence/before_raw/` và `evidence/before_configured/`
- [ ] `evidence/after_raw/` và `evidence/after_configured/`
- [ ] `evidence/architecture/`
- [ ] 04 URL Actions run RED/GREEN/RED/GREEN + 04 commit SHA
- [ ] Link repo và ảnh màn hình có terminal / URL / commit SHA; không cắt mất ngữ cảnh
- [ ] Các finding được triage, không chép lại mô tả detector thay cho suy luận
- [ ] Tuyệt đối không có seed phrase, private key, credentials

**Nhận xét cuối cùng (5–7 câu):** ...
