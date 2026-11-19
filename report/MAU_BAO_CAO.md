# NT547 - LAB 06 - BÁO CÁO (TỰ ĐIỀN)

**MSSV:** 2452182  | **Họ tên:** Hồ Lê Anh Trường | **Lớp:** ...
**Session code tự sinh:** SC-C56214 | **Tên contract:** TipJar_2182
**Solidity / Slither:** 0.8.24 / 0.11.6 | **Ngày hoàn thành:** ...
**URL GitHub repository:** https://github.com/UIT24521892/NT547-Lab06-2452182

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
| `weak-prng` (High), `uiDay()`, dòng 37 trước sửa | FP trong ngữ cảnh | Hàm `view` chỉ trả chỉ số ngày trong tuần. Trong mã hiện tại không có đường dùng kết quả cho phân quyền hoặc chi trả. | Viết phép cộng modulo bằng `addmod(block.timestamp / 1 days, 4, 7)`. Kết quả tương đương biểu thức cũ. | Hết finding ở cả hai scan AFTER. |
| `controlled-delegatecall` (High), `execute()`, dòng 57 trước sửa | TP | Hàm công khai nhận `target` và `data` từ caller. `delegatecall` chạy mã đích trong ngữ cảnh storage của TipJar. | Thêm `onlyOwner`, xác nhận đích là contract và dùng `call` để mã đích chạy trong ngữ cảnh của chính nó. | Hết `controlled-delegatecall` và `missing-zero-check`. Raw còn thông tin `low-level-calls`. |
| `suicidal` (High), `sunset()`, dòng 53 trước sửa | TP | Caller bất kỳ có thể kích hoạt chuyển toàn bộ ETH từ contract vì hàm chưa kiểm tra quyền. | Thêm `onlyOwner` vào `sunset()`. | Hết detector `suicidal`. Cảnh báo của compiler về `selfdestruct` vẫn xuất hiện. |
| `tx-origin` (Medium), `updateOwner()`, dòng 62 trước sửa | TP | Điều kiện cũ kiểm tra tài khoản khởi tạo giao dịch, cho phép một lời gọi gián tiếp vượt qua kiểm tra danh tính caller. | Kiểm tra `msg.sender == owner` và giữ điều kiện địa chỉ mới khác zero. | Hết `tx-origin`. Raw báo Low `events-access` do chưa phát sự kiện khi đổi owner. |
| `unchecked-lowlevel` (Medium), `collectFees()`, dòng 42 trước sửa | TP | Nếu bên nhận từ chối ETH, low-level call trả `false` nhưng giao dịch bên ngoài vẫn có thể được ghi nhận thành công. | Kiểm tra giá trị trả về và revert khi gửi thất bại. | Hết `unchecked-lowlevel`. Raw còn thông tin `low-level-calls`. |
| `timestamp` (Low), `vestStep()`, dòng 46 trước sửa | Chấp nhận theo ngữ cảnh | Timestamp chỉ kiểm tra mốc mở khóa. Hàm yêu cầu `onlyOwner`, ghi `cooldownEnd` mới trước khi gửi tiền và kiểm tra kết quả gửi. | Giữ cơ chế cooldown. Thời điểm có thể lệch sát ngưỡng, nhưng timestamp không quyết định người nhận hoặc quyền gọi. | Vẫn có trong raw. Bộ lọc Low loại khỏi configured. |

- Kịch bản TP cho `unchecked-lowlevel`: owner gọi `collectFees` để chuyển ETH đến một contract từ chối nhận tiền. Lời gọi nội bộ trả về `false`. Trong baseline, giao dịch bên ngoài vẫn có thể báo thành công dù ETH chưa chuyển. Bản sửa revert khi lời gọi thất bại.
- Severity và rủi ro: `weak-prng` được xếp High vì giá trị ngẫu nhiên lấy từ timestamp có thể gây hậu quả lớn nếu dùng để chia thưởng. `uiDay()` chỉ tính ngày trong tuần để hiển thị, nên trong source hiện tại kết quả không ảnh hưởng số dư hay quyền gọi.
- Diff và bằng chứng: `evidence/fix.diff` đối chiếu bản vá với commit baseline. Raw giảm từ 12 xuống 7 findings (0 High, 0 Medium, 2 Low, 5 Informational). Configured giảm từ 5 xuống 0. Xem `evidence/after_raw/` và `evidence/after_configured/`.
- Hai finding Low là `events-access` (có thể bổ sung event để theo dõi thay đổi owner) và `timestamp` (đã triage ở trên). Năm finding Informational gồm bốn `low-level-calls`, đều kiểm tra kết quả trả về, và một `naming-convention` do tên contract có hậu tố MSSV từ generator.
- Không dùng chỉ thị `slither-disable-next-line`. Biểu thức mới trong `uiDay()` trả cùng chỉ số ngày và không còn bị detector `weak-prng` báo.

## 3. Kiến trúc / Inheritance (1,5 điểm)

- Lệnh printer đã chạy: ...
- Ảnh `evidence/architecture/inheritance.png` (hoặc .dot, nếu Graphviz chưa có): ...
- Access control nằm ở ...; logic số dư nằm ở ...; contract triển khai nằm ở ...
- Giải thích 3–5 câu điểm audit cần bắt đầu: ...

## 4. Red -> Green CI (2,5 điểm)

| Phase | Commit (full/short SHA) | Run URL | Kết quả | Detector khiến RED / lý do GREEN |
|---|---|---|---|---|
| Baseline vulnerable | ab0c3097319dd4ff67d303455e1db25efb6f6a50 | https://github.com/UIT24521892/NT547-Lab06-2452182/actions/runs/44524423141 | RED | Step Slither thất bại với 5 findings: weak-prng, controlled-delegatecall, suicidal (High); tx-origin, unchecked-lowlevel (Medium). Đã đối chiếu ảnh log Actions của baseline. |
| Patched | | | GREEN | |

- So sánh local `--fail-none` (thu thập findings) với CI `fail-on: medium`: local vẫn trả exit code 0 khi có findings để ghi JSON/CSV/log phục vụ triage; CI thất bại khi còn finding từ Medium trở lên. Baseline local exit 0 nhưng Actions RED vì còn 3 High và 2 Medium.
- `exclude_low/informational` thay đổi kết quả hiển thị ra sao: baseline raw có 12 findings; configured chỉ còn 5 do loại 2 Low và 5 Informational, không làm mất High/Medium và không sửa nguyên nhân trong source.

## 5. Mutation RED -> GREEN (1,5 điểm)

- Mutation một dòng: `require(msg.sender == owner, "not owner")` -> `require(tx.origin == owner, "not owner")` trong `modifier onlyOwner`.
- Detector kỳ vọng: `tx-origin` (mức Medium); xác nhận của em từ CI: ...

| Phase | Commit SHA | Run URL | Kết quả |
|---|---|---|---|
| Mutation | | | RED |
| Revert mutation | | | GREEN |

- Giải thích sự thay đổi về nguồn định danh/authorization: ...

## 6. Bằng chứng, tự kiểm

- [x] `AuditTarget.sol`, `lab_identity.json`
- [x] `evidence/before_raw/` và `evidence/before_configured/`
- [x] `evidence/after_raw/` và `evidence/after_configured/`
- [ ] `evidence/architecture/`
- [ ] 04 URL Actions run RED/GREEN/RED/GREEN + 04 commit SHA
- [ ] Link repo và ảnh màn hình có terminal / URL / commit SHA; không cắt mất ngữ cảnh
- [ ] Các finding được triage, không chép lại mô tả detector thay cho suy luận
- [ ] Tuyệt đối không có seed phrase, private key, credentials

**Nhận xét cuối cùng (5–7 câu):** ...
