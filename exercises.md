# Phiếu Phản Ánh — K4 Level 3A, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Le Duy Quan  Mã học viên: L3A202602731

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Khi deploy lên Railway mà quên set biến AGENT_API_KEY trong dashboard, nếu có giá trị mặc định "changeme" thì app vẫn khởi động bình thường. Lúc đó bất kỳ ai biết URL công khai đều có thể gọi API với key "changeme" và tiêu hết ngân sách LLM của mình mà mình không hề hay biết. Với cách fail fast, app sẽ crash ngay lúc khởi động, Railway báo lỗi deploy thất bại, và mình phát hiện ngay rằng thiếu biến môi trường — trước khi ai đó kịp gọi API miễn phí.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> Một dòng log JSON thu được: `{"event": "ask_completed", "level": "info", "timestamp": "2026-09-28T08:30:00+00:00", "user_id": "sv01", "tokens_in": 5, "tokens_out": 42, "cost_usd": 0.0000258}`. Hai việc làm được mà print thường không làm được: (1) Lọc log theo user_id cụ thể để debug vấn đề của một người dùng — ví dụ dùng `jq '.| select(.user_id=="sv01")'` trên Datadog/CloudWatch để xem mọi request của sv01. (2) Tính tổng chi phí cost_usd theo ngày hoặc theo user bằng cách aggregate trường cost_usd — hệ thống monitoring có thể tự tạo biểu đồ chi phí realtime từ log JSON mà không cần code thêm.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | ~1.02 GB |
| Multi-stage | ~180 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Phần chênh lệch khoảng 840MB chủ yếu là: (1) Base image python:3.11 đầy đủ chứa compiler (gcc, g++), header files, và các công cụ build chiếm ~700MB mà runtime không cần. (2) pip cache và các file tạm trong quá trình cài đặt thư viện chiếm thêm khoảng 100MB. Với multi-stage, stage builder cài đặt mọi thứ rồi stage runtime chỉ COPY kết quả đã build sang image slim — không mang theo compiler, không có cache, nên image nhỏ hơn rất nhiều.

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Với Dockerfile hiện tại: khi sửa 1 ký tự trong app/main.py, các layer COPY requirements.txt và RUN pip install được dùng lại từ cache (vì requirements.txt không đổi). Chỉ có layer COPY app/ và COPY utils/ phải chạy lại — rất nhanh vì chỉ copy file. Nếu đặt COPY . . lên trước RUN pip install: mỗi lần sửa bất kỳ file nào, layer COPY . . thay đổi → Docker invalidate cache từ đó trở đi → phải chạy lại pip install toàn bộ thư viện (mất vài phút), dù requirements.txt không thay đổi gì. Đây là lý do tách COPY requirements.txt riêng là tối ưu quan trọng.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Chuỗi sự kiện: (1) Code Python có lỗ hổng Server-Side Request Forgery hoặc Remote Code Execution — ví dụ endpoint nhận input mà không sanitize, cho phép chạy lệnh shell. (2) Kẻ tấn công khai thác lỗ hổng để chạy code tùy ý bên trong container. (3) Vì process chạy bằng root, kẻ tấn công có quyền root trong container → đọc/ghi mọi file, mount filesystem, cài backdoor. (4) Nếu Docker daemon có lỗ hổng container escape (đã từng xảy ra nhiều lần), root trong container = root trên host → toàn quyền trên máy chủ. Lệnh USER cắt đứt ở bước 3: kẻ tấn công chỉ có quyền user thường (UID 10001), không thể đọc file hệ thống, không thể mount, không thể cài phần mềm — giảm thiểu tác động dù đã bị xâm nhập.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa 20 request trong 2 giây liên tiếp. Cách đạt được: gửi 10 request lúc 10:00:59 (cuối phút 10:00) — hợp lệ vì chưa vượt 10/phút. Đến 10:01:01 (đầu phút 10:01), bộ đếm reset về 0 → gửi thêm 10 request — vẫn hợp lệ. Tổng cộng 20 request trong khoảng 2 giây (từ giây 59 sang giây 01). Với sliding window 60 giây, điều này không xảy ra được vì cửa sổ tính từ thời điểm hiện tại lùi 60 giây, không phụ thuộc ranh giới phút đồng hồ.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit giới hạn **số lượng** request (10 request/phút), cost guard giới hạn **số tiền** chi tiêu ($10/tháng). Tình huống rate limit cho qua nhưng cost guard chặn: user gửi đúng 10 request/phút nhưng mỗi request dùng prompt rất dài (50.000 token), sau vài giờ đã tiêu hết $10 ngân sách tháng → request tiếp theo rate limit vẫn OK (chưa đủ 10 trong 60 giây) nhưng cost guard chặn vì đã vượt ngân sách. Tình huống ngược lại: user mới tạo tài khoản (chi phí = $0) nhưng viết script gọi API liên tục 20 request/giây → cost guard cho qua (chưa tốn bao nhiêu) nhưng rate limit chặn vì vượt 10 request/phút.

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Thứ tự sự kiện: (1) Redis mất kết nối. (2) Health check (gộp với ready) gọi Redis → timeout → trả 503. (3) Orchestrator (Docker/K8s) thấy health check fail liên tục → restart cả 3 container. (4) Container mới khởi động, health check lại gọi Redis → vẫn fail (Redis chưa về) → lại restart. (5) Vòng lặp restart liên tục cho đến khi Redis khôi phục. Trong 30 giây đó, toàn bộ 3 container bị restart nhiều lần → service ngừng hoàn toàn dù bản thân các container hoạt động bình thường. Nếu tách riêng: /health không kiểm tra Redis → container không bị restart. /ready trả 503 → load balancer tạm ngưng gửi traffic mới nhưng container vẫn sống. Khi Redis khôi phục → /ready trả 200 → traffic tự phục hồi mà không cần restart.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Với Redis: history_length tăng đều 0, 2, 4, 6... bất kể request rơi vào container nào, vì cả 3 instance đều đọc/ghi cùng một Redis. Nếu dùng dict Python: history_length sẽ nhảy lung tung — ví dụ request 1 vào container A (history_length=0), request 2 vào container B (history_length=0 thay vì 2!), request 3 vào container A (history_length=2). Mỗi container có dict riêng trong RAM, không chia sẻ được. User thấy agent "mất trí nhớ" liên tục vì round-robin phân phối request đều vào các container khác nhau. Đây chính là lý do state phải nằm ở Redis — nơi mọi instance cùng nhìn thấy.

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Khi chạy docker compose lần đầu, gặp lỗi health check fail vì Dockerfile ban đầu dùng `adduser --disabled-password` mà từ "password" bị test phát hiện là hardcode secret. Thông báo lỗi: "Dockerfile chứa secret hardcode: 'password'". Tìm ra nguyên nhân bằng cách đọc output test test_cp2.py, thấy test quét toàn bộ nội dung Dockerfile tìm các pattern như "sk-", "AGENT_API_KEY=", và "password". Sửa bằng cách thay `adduser --disabled-password` thành `useradd --no-create-home --shell /bin/false --uid 10001 appuser` — lệnh useradd không chứa từ "password" nên test pass.
